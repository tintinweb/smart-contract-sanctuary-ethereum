// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./base/EternalStorage.sol";
import "./base/ISettings.sol";
import "./base/IACL.sol";

/**
 * @dev Business-logic for Settings
 */
 contract Settings is EternalStorage, ISettings {

  modifier assertIsAuthorized (address _context) {
    if (_context == address(this)) {
      require(acl().isAdmin(msg.sender), 'must be admin');
    } else {
      require(msg.sender == _context, 'must be context owner');
    }
    _;
  }

  /**
   * Constructor
   * @param _acl ACL address.
   */
  constructor (address _acl) {
    dataAddress["acl"] = _acl;
  }

  // ISettings

  function acl() public view override returns (IACL) {
    return IACL(dataAddress["acl"]);
  }

  function getAddress(address _context, bytes32 _key) public view override returns (address) {
    return dataAddress[__ab(_context, _key)];
  }

  function getRootAddress(bytes32 _key) public view override returns (address) {
    return getAddress(address(this), _key);
  }

  function setAddress(address _context, bytes32 _key, address _value) external override assertIsAuthorized(_context) {
    dataAddress[__ab(_context, _key)] = _value;
    emit SettingChanged(_context, _key, msg.sender, 'address');
  }

  function getAddresses(address _context, bytes32 _key) public view override returns (address[] memory) {
    return dataManyAddresses[__ab(_context, _key)];
  }

  function getRootAddresses(bytes32 _key) public view override returns (address[] memory) {
    return getAddresses(address(this), _key);
  }

  function setAddresses(address _context, bytes32 _key, address[] calldata _value) external override assertIsAuthorized(_context) {
    dataManyAddresses[__ab(_context, _key)] = _value;
    emit SettingChanged(_context, _key, msg.sender, 'addresses');
  }

  function getBool(address _context, bytes32 _key) public view override returns (bool) {
    return dataBool[__ab(_context, _key)];
  }

  function getRootBool(bytes32 _key) public view override returns (bool) {
    return getBool(address(this), _key);
  }

  function setBool(address _context, bytes32 _key, bool _value) external override assertIsAuthorized(_context) {
    dataBool[__ab(_context, _key)] = _value;
    emit SettingChanged(_context, _key, msg.sender, 'bool');
  }

  function getUint256(address _context, bytes32 _key) public view override returns (uint256) {
    return dataUint256[__ab(_context, _key)];
  }

  function getRootUint256(bytes32 _key) public view override returns (uint256) {
    return getUint256(address(this), _key);
  }

  function setUint256(address _context, bytes32 _key, uint256 _value) external override assertIsAuthorized(_context) {
    dataUint256[__ab(_context, _key)] = _value;
    emit SettingChanged(_context, _key, msg.sender, 'uint256');
  }

  function getString(address _context, bytes32 _key) public view override returns (string memory) {
    return dataString[__ab(_context, _key)];
  }

  function getRootString(bytes32 _key) public view override returns (string memory) {
    return getString(address(this), _key);
  }

  function setString(address _context, bytes32 _key, string memory _value) external override assertIsAuthorized(_context) {
    dataString[__ab(_context, _key)] = _value;
    emit SettingChanged(_context, _key, msg.sender, 'string');
  }

  function getTime() public view override returns (uint256) {
    return block.timestamp;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/**
 * @dev Base contract for any upgradeable contract that wishes to store data.
 */
contract EternalStorage {
  // scalars
  mapping(string => address) dataAddress;
  mapping(string => bytes32) dataBytes32;
  mapping(string => int256) dataInt256;
  mapping(string => uint256) dataUint256;
  mapping(string => bool) dataBool;
  mapping(string => string) dataString;
  mapping(string => bytes) dataBytes;
  // arrays
  mapping(string => address[]) dataManyAddresses;
  mapping(string => bytes32[]) dataManyBytes32s;
  mapping(string => int256[]) dataManyInt256;
  mapping(string => uint256[]) dataManyUint256;
  // helpers
  function __i (uint256 i1, string memory s) internal pure returns (string memory) {
    return string(abi.encodePacked(i1, s));
  }
  function __a (address a1, string memory s) internal pure returns (string memory) {
    return string(abi.encodePacked(a1, s));
  }
  function __aa (address a1, address a2, string memory s) internal pure returns (string memory) {
    return string(abi.encodePacked(a1, a2, s));
  }
  function __b (bytes32 b1, string memory s) internal pure returns (string memory) {
    return string(abi.encodePacked(b1, s));
  }
  function __ii (uint256 i1, uint256 i2, string memory s) internal pure returns (string memory) {
    return string(abi.encodePacked(i1, i2, s));
  }
  function __ia (uint256 i1, address a1, string memory s) internal pure returns (string memory) {
    return string(abi.encodePacked(i1, a1, s));
  }
  function __iaa (uint256 i1, address a1, address a2, string memory s) internal pure returns (string memory) {
    return string(abi.encodePacked(i1, a1, a2, s));
  }
  function __iaaa (uint256 i1, address a1, address a2, address a3, string memory s) internal pure returns (string memory) {
    return string(abi.encodePacked(i1, a1, a2, a3, s));
  }
  function __ab (address a1, bytes32 b1) internal pure returns (string memory) {
    return string(abi.encodePacked(a1, b1));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./ISettingsKeys.sol";
import "./IACL.sol";

/**
 * @dev Settings.
 */
abstract contract ISettings is ISettingsKeys {
  /**
   * @dev Get ACL.
   */
  function acl() public view virtual returns (IACL);

  /**
   * @dev Get an address.
   *
   * @param _context The context.
   * @param _key The key.
   *
   * @return The value.
   */
  function getAddress(address _context, bytes32 _key) public view virtual returns (address);

  /**
   * @dev Get an address in the root context.
   *
   * @param _key The key.
   *
   * @return The value.
   */
  function getRootAddress(bytes32 _key) public view virtual returns (address);

  /**
   * @dev Set an address.
   *
   * @param _context The context.
   * @param _key The key.
   * @param _value The value.
   */
  function setAddress(address _context, bytes32 _key, address _value) external virtual;

  /**
   * @dev Get an address.
   *
   * @param _context The context.
   * @param _key The key.
   *
   * @return The value.
   */
  function getAddresses(address _context, bytes32 _key) public view virtual returns (address[] memory);

  /**
   * @dev Get an address in the root context.
   *
   * @param _key The key.
   *
   * @return The value.
   */
  function getRootAddresses(bytes32 _key) public view virtual returns (address[] memory);

  /**
   * @dev Set an address.
   *
   * @param _context The context.
   * @param _key The key.
   * @param _value The value.
   */
  function setAddresses(address _context, bytes32 _key, address[] calldata _value) external virtual;

  /**
   * @dev Get a boolean.
   *
   * @param _context The context.
   * @param _key The key.
   *
   * @return The value.
   */
  function getBool(address _context, bytes32 _key) public view virtual returns (bool);

  /**
   * @dev Get a boolean in the root context.
   *
   * @param _key The key.
   *
   * @return The value.
   */
  function getRootBool(bytes32 _key) public view virtual returns (bool);

  /**
   * @dev Set a boolean.
   *
   * @param _context The context.
   * @param _key The key.
   * @param _value The value.
   */
  function setBool(address _context, bytes32 _key, bool _value) external virtual;

  /**
   * @dev Get a number.
   *
   * @param _context The context.
   * @param _key The key.
   *
   * @return The value.
   */
  function getUint256(address _context, bytes32 _key) public view virtual returns (uint256);

  /**
   * @dev Get a number in the root context.
   *
   * @param _key The key.
   *
   * @return The value.
   */
  function getRootUint256(bytes32 _key) public view virtual returns (uint256);

  /**
   * @dev Set a number.
   *
   * @param _context The context.
   * @param _key The key.
   * @param _value The value.
   */
  function setUint256(address _context, bytes32 _key, uint256 _value) external virtual;

  /**
   * @dev Get a string.
   *
   * @param _context The context.
   * @param _key The key.
   *
   * @return The value.
   */
  function getString(address _context, bytes32 _key) public view virtual returns (string memory);

  /**
   * @dev Get a string in the root context.
   *
   * @param _key The key.
   *
   * @return The value.
   */
  function getRootString(bytes32 _key) public view virtual returns (string memory);

  /**
   * @dev Set a string.
   *
   * @param _context The context.
   * @param _key The key.
   * @param _value The value.
   */
  function setString(address _context, bytes32 _key, string memory _value) external virtual;


  /**
   * @dev Get current block time.
   *
   * @return Block time.
   */
  function getTime() external view virtual returns (uint256);


  // events

  /**
   * @dev Emitted when a setting gets updated.
   * @param context The context.
   * @param key The key.
   * @param caller The caller.
   * @param keyType The type of setting which changed.
   */
  event SettingChanged (address indexed context, bytes32 indexed key, address indexed caller, string keyType);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/**
 * @dev ACL (Access Control List).
 */
interface IACL {
  // admin

  /**
   * @dev Check if given address has the admin role.
   * @param _addr Address to check.
   * @return true if so
   */
  function isAdmin(address _addr) external view returns (bool);
  /**
   * @dev Assign admin role to given address.
   * @param _addr Address to assign to.
   */
  function addAdmin(address _addr) external;
  /**
   * @dev Remove admin role from given address.
   * @param _addr Address to remove from.
   */
  function removeAdmin(address _addr) external;

  // contexts

  /**
   * @dev Get the no. of existing contexts.
   * @return no. of contexts
   */
  function getNumContexts() external view returns (uint256);
  /**
   * @dev Get context at given index.
   * @param _index Index into list of all contexts.
   * @return context name
   */
  function getContextAtIndex(uint256 _index) external view returns (bytes32);
  /**
   * @dev Get the no. of addresses belonging to (i.e. who have been assigned roles in) the given context.
   * @param _context Name of context.
   * @return no. of addresses
   */
  function getNumUsersInContext(bytes32 _context) external view returns (uint256);
  /**
   * @dev Get the address at the given index in the list of addresses belonging to the given context.
   * @param _context Name of context.
   * @param _index Index into the list of addresses
   * @return the address
   */
  function getUserInContextAtIndex(bytes32 _context, uint _index) external view returns (address);

  // users

  /**
   * @dev Get the no. of contexts the given address belongs to (i.e. has an assigned role in).
   * @param _addr Address.
   * @return no. of contexts
   */
  function getNumContextsForUser(address _addr) external view returns (uint256);
  /**
   * @dev Get the contexts at the given index in the list of contexts the address belongs to.
   * @param _addr Address.
   * @param _index Index of context.
   * @return Context name
   */
  function getContextForUserAtIndex(address _addr, uint256 _index) external view returns (bytes32);
  /**
   * @dev Get whether given address has a role assigned in the given context.
   * @param _context Context name.
   * @param _addr Address.
   * @return true if so
   */
  function userSomeHasRoleInContext(bytes32 _context, address _addr) external view returns (bool);

  // role groups

  /**
   * @dev Get whether given address has a role in the given rolegroup in the given context.
   * @param _context Context name.
   * @param _addr Address.
   * @param _roleGroup The role group.
   * @return true if so
   */
  function hasRoleInGroup(bytes32 _context, address _addr, bytes32 _roleGroup) external view returns (bool);
  /**
   * @dev Set the roles for the given role group.
   * @param _roleGroup The role group.
   * @param _roles List of roles.
   */
  function setRoleGroup(bytes32 _roleGroup, bytes32[] calldata _roles) external;
  /**
   * @dev Get whether given given name represents a role group.
   * @param _roleGroup The role group.
   * @return true if so
   */
  function isRoleGroup(bytes32 _roleGroup) external view returns (bool);
  /**
   * @dev Get the list of roles in the given role group
   * @param _roleGroup The role group.
   * @return role list
   */
  function getRoleGroup(bytes32 _roleGroup) external view returns (bytes32[] memory);
  /**
   * @dev Get the list of role groups which contain given role
   * @param _role The role.
   * @return rolegroup list
   */
  function getRoleGroupsForRole(bytes32 _role) external view returns (bytes32[] memory);

  // roles

  /**
   * @dev Get whether given address has given role in the given context.
   * @param _context Context name.
   * @param _addr Address.
   * @param _role The role.
   * @return either `DOES_NOT_HAVE_ROLE` or one of the `HAS_ROLE_...` constants
   */
  function hasRole(bytes32 _context, address _addr, bytes32 _role) external view returns (uint256);

  /**
   * @dev Get whether given address has any of the given roles in the given context.
   * @param _context Context name.
   * @param _addr Address.
   * @param _roles The role list.
   * @return true if so
   */
  function hasAnyRole(bytes32 _context, address _addr, bytes32[] calldata _roles) external view returns (bool);

  /**
   * @dev Assign a role to the given address in the given context.
   * @param _context Context name.
   * @param _addr Address.
   * @param _role The role.
   */
  function assignRole(bytes32 _context, address _addr, bytes32 _role) external;

  /**
   * @dev Assign a role to the given address in the given context and id.
   * @param _context Context name.
   * @param _id Id.
   * @param _addr Address.
   * @param _role The role.
   */
  // function assignRoleToId(bytes32 _context, bytes32 _id, address _addr, bytes32 _role) external;

  /**
   * @dev Remove a role from the given address in the given context.
   * @param _context Context name.
   * @param _addr Address.
   * @param _role The role to unassign.
   */
  function unassignRole(bytes32 _context, address _addr, bytes32 _role) external;
  
  /**
   * @dev Remove a role from the given address in the given context.
   * @param _context Context name.
   * @param _id Id.
   * @param _addr Address.
   * @param _role The role to unassign.
   */
  // function unassignRoleToId(bytes32 _context, bytes32 _id, address _addr, bytes32 _role) external;
  
  /**
   * @dev Get all role for given address in the given context.
   * @param _context Context name.
   * @param _addr Address.
   * @return list of roles
   */
  function getRolesForUser(bytes32 _context, address _addr) external view returns (bytes32[] memory);
  /**
   * @dev Get all addresses for given role in the given context.
   * @param _context Context name.
   * @param _role Role.
   * @return list of roles
   */
  function getUsersForRole(bytes32 _context, bytes32 _role) external view returns (address[] memory);

  // who can assign roles

  /**
   * @dev Add given rolegroup as an assigner for the given role.
   * @param _roleToAssign The role.
   * @param _assignerRoleGroup The role group that should be allowed to assign this role.
   */
  function addAssigner(bytes32 _roleToAssign, bytes32 _assignerRoleGroup) external;
  /**
   * @dev Remove given rolegroup as an assigner for the given role.
   * @param _roleToAssign The role.
   * @param _assignerRoleGroup The role group that should no longer be allowed to assign this role.
   */
  function removeAssigner(bytes32 _roleToAssign, bytes32 _assignerRoleGroup) external;
  /**
   * @dev Get all rolegroups that are assigners for the given role.
   * @param _role The role.
   * @return list of rolegroups
   */
  function getAssigners(bytes32 _role) external view returns (bytes32[] memory);
  /**
   * @dev Get whether given address can assign given role within the given context.

   * @param _context Context name.
   * @param _assigner Assigner address.
   * @param _assignee Assignee address.
   * @param _role The role to assign.
   * @return one of the `CANNOT_ASSIGN...` or `CAN_ASSIGN_...` constants
   */
  function canAssign(bytes32 _context, address _assigner, address _assignee, bytes32 _role) external view returns (uint256);

  // utility methods

  /**
   * @dev Generate the context name which represents the given address.
   *
   * @param _addr Address.
   * @return context name.
   */
  function generateContextFromAddress (address _addr) external pure returns (bytes32);

  /**
   * @dev Emitted when a role group gets updated.
   * @param roleGroup The rolegroup which got updated.
   */
  event RoleGroupUpdated(bytes32 indexed roleGroup);

  /**
   * @dev Emitted when a role gets assigned.
   * @param context The context within which the role got assigned.
   * @param addr The address the role got assigned to.
   * @param role The role which got assigned.
   */
  event RoleAssigned(bytes32 indexed context, address indexed addr, bytes32 indexed role);

  /**
   * @dev Emitted when a role gets unassigned.
   * @param context The context within which the role got assigned.
   * @param addr The address the role got assigned to.
   * @param role The role which got unassigned.
   */
  event RoleUnassigned(bytes32 indexed context, address indexed addr, bytes32 indexed role);

  /**
   * @dev Emitted when a role assigner gets added.
   * @param role The role that can be assigned.
   * @param roleGroup The rolegroup that will be able to assign this role.
   */
  event AssignerAdded(bytes32 indexed role, bytes32 indexed roleGroup);

  /**
   * @dev Emitted when a role assigner gets removed.
   * @param role The role that can be assigned.
   * @param roleGroup The rolegroup that will no longer be able to assign this role.
   */
  event AssignerRemoved(bytes32 indexed role, bytes32 indexed roleGroup);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/**
 * @dev Settings keys.
 */
contract ISettingsKeys {
  // BEGIN: Generated by script outputConstants.js
  // DO NOT MANUALLY MODIFY THESE VALUES!
  bytes32 constant public SETTING_MARKET = 0x6f244974cc67342b1bd623d411fd8100ec9eddbac05348e71d1a9296de6264a5;
  bytes32 constant public SETTING_FEEBANK = 0x6a4d660b9f1720511be22f039683db86d0d0d207c2ad9255325630800d4fb539;
  bytes32 constant public SETTING_ETHER_TOKEN = 0xa449044fc5332c1625929b3afecb2f821955279285b4a8406a6ffa8968c1b7cf;
  bytes32 constant public SETTING_ENTITY_IMPL = 0x098afcb3a137a2ba8835fbf7daecb275af5afb3479f12844d5b7bfb8134e7ced;
  bytes32 constant public SETTING_POLICY_IMPL = 0x0e8925aa0bfe65f831f6c9099dd95b0614eb69312630ef3497bee453d9ed40a9;
  bytes32 constant public SETTING_MARKET_IMPL = 0xc72bfe3e0f1799ce0d90c4c72cf8f07d0cfa8121d51cb05d8c827f0896d8c0b6;
  bytes32 constant public SETTING_FEEBANK_IMPL = 0x9574e138325b5c365da8d5cc75cf22323ed6f3ce52fac5621225020a162a4c61;
  bytes32 constant public SETTING_ENTITY_DEPLOYER = 0x1bf52521006d8a3718b0692b7f32c8ee781bfed9e9215eb5b8fc3b34749fb5b5;
  bytes32 constant public SETTING_ENTITY_DELEGATE = 0x063693c9545b949ff498535f9e0aa95ada8e88c062d28e2f219b896e151e1266;
  bytes32 constant public SETTING_POLICY_DELEGATE = 0x5c6c7d4897f0ae38084370e7a61ea386e95c7f54629c0b793a0ac47751f12405;
  // END: Generated by script outputConstants.js
}