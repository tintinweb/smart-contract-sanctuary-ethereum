// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;
import "./base/IACL.sol";
import "./base/IACLConstants.sol";
import "./base/IAccessControl.sol";

/**
 * @dev Library for managing addresses assigned to a Role within a context.
 */
library Assignments {
    struct RoleUsers {
        mapping(address => uint256) map;
        address[] list;
    }

    struct UserRoles {
        mapping(bytes32 => uint256) map;
        bytes32[] list;
    }

    struct Context {
        mapping(bytes32 => RoleUsers) roleUsers;
        mapping(address => UserRoles) userRoles;
        mapping(address => uint256) userMap;
        address[] userList;
    }

    /**
     * @dev give an address access to a role
     */
    function addRoleForUser(
        Context storage _context,
        bytes32 _role,
        address _addr
    ) internal {
        UserRoles storage ur = _context.userRoles[_addr];
        RoleUsers storage ru = _context.roleUsers[_role];

        // new user?
        if (_context.userMap[_addr] == 0) {
            _context.userList.push(_addr);
            _context.userMap[_addr] = _context.userList.length;
        }

        // set role for user
        if (ur.map[_role] == 0) {
            ur.list.push(_role);
            ur.map[_role] = ur.list.length;
        }

        // set user for role
        if (ru.map[_addr] == 0) {
            ru.list.push(_addr);
            ru.map[_addr] = ru.list.length;
        }
    }

    /**
     * @dev remove an address' access to a role
     */
    function removeRoleForUser(
        Context storage _context,
        bytes32 _role,
        address _addr
    ) internal {
        UserRoles storage ur = _context.userRoles[_addr];
        RoleUsers storage ru = _context.roleUsers[_role];

        // remove from addr -> role map
        uint256 idx = ur.map[_role];
        if (idx > 0) {
            uint256 actualIdx = idx - 1;

            // replace item to remove with last item in list and update mappings
            if (ur.list.length - 1 > actualIdx) {
                ur.list[actualIdx] = ur.list[ur.list.length - 1];
                ur.map[ur.list[actualIdx]] = actualIdx + 1;
            }

            ur.list.pop();
            ur.map[_role] = 0;
        }

        // remove from role -> addr map
        idx = ru.map[_addr];
        if (idx > 0) {
            uint256 actualIdx = idx - 1;

            // replace item to remove with last item in list and update mappings
            if (ru.list.length - 1 > actualIdx) {
                ru.list[actualIdx] = ru.list[ru.list.length - 1];
                ru.map[ru.list[actualIdx]] = actualIdx + 1;
            }

            ru.list.pop();
            ru.map[_addr] = 0;
        }

        // remove user if they don't have roles anymore
        if (ur.list.length == 0) {
            uint256 actualIdx = _context.userMap[_addr] - 1;

            // replace item to remove with last item in list and update mappings
            if (_context.userList.length - 1 > actualIdx) {
                _context.userList[actualIdx] = _context.userList[_context.userList.length - 1];
                _context.userMap[_context.userList[actualIdx]] = actualIdx + 1;
            }

            _context.userList.pop();
            _context.userMap[_addr] = 0;
        }
    }

    /**
     * @dev check if an address has a role
     * @return bool
     */
    function hasRoleForUser(
        Context storage _context,
        bytes32 _role,
        address _addr
    ) internal view returns (bool) {
        UserRoles storage ur = _context.userRoles[_addr];

        return (ur.map[_role] > 0);
    }

    /**
     * @dev get all roles for address
     * @return bytes32[]
     */
    function getRolesForUser(Context storage _context, address _addr) internal view returns (bytes32[] storage) {
        UserRoles storage ur = _context.userRoles[_addr];

        return ur.list;
    }

    /**
     * @dev get all addresses assigned the given role
     * @return address[]
     */
    function getUsersForRole(Context storage _context, bytes32 _role) internal view returns (address[] storage) {
        RoleUsers storage ru = _context.roleUsers[_role];

        return ru.list;
    }

    /**
     * @dev get number of addresses with roles
     * @return uint256
     */
    function getNumUsers(Context storage _context) internal view returns (uint256) {
        return _context.userList.length;
    }

    /**
     * @dev get addresses at given index in list of addresses
     * @return uint256
     */
    function getUserAtIndex(Context storage _context, uint256 _index) internal view returns (address) {
        return _context.userList[_index];
    }

    /**
     * @dev get whether given addresses has a role in this context
     * @return uint256
     */
    function hasUser(Context storage _context, address _addr) internal view returns (bool) {
        return _context.userMap[_addr] != 0;
    }
}

/**
 * @dev Library for lists of byte32 value.
 */
library Bytes32 {
    struct Set {
        mapping(bytes32 => uint256) map;
        bytes32[] list;
    }

    /**
     * @dev add a value
     */
    function add(Set storage _obj, bytes32 _assignerRole) internal {
        if (_obj.map[_assignerRole] == 0) {
            _obj.list.push(_assignerRole);
            _obj.map[_assignerRole] = _obj.list.length;
        }
    }

    /**
     * @dev remove an value for this role
     */
    function remove(Set storage _obj, bytes32 _assignerRole) internal {
        uint256 idx = _obj.map[_assignerRole];

        if (idx > 0) {
            uint256 actualIdx = idx - 1;

            // replace item to remove with last item in list and update mappings
            if (_obj.list.length - 1 > actualIdx) {
                _obj.list[actualIdx] = _obj.list[_obj.list.length - 1];
                _obj.map[_obj.list[actualIdx]] = actualIdx + 1;
            }

            _obj.list.pop();
            _obj.map[_assignerRole] = 0;
        }
    }

    /**
     * @dev remove all values
     */
    function clear(Set storage _obj) internal {
        for (uint256 i = 0; i < _obj.list.length; i += 1) {
            _obj.map[_obj.list[i]] = 0;
        }

        delete _obj.list;
    }

    /**
     * @dev get no. of values
     */
    function size(Set storage _obj) internal view returns (uint256) {
        return _obj.list.length;
    }

    /**
     * @dev get whether value exists.
     */
    function has(Set storage _obj, bytes32 _value) internal view returns (bool) {
        return 0 < _obj.map[_value];
    }

    /**
     * @dev get value at index.
     */
    function get(Set storage _obj, uint256 _index) internal view returns (bytes32) {
        return _obj.list[_index];
    }

    /**
     * @dev Get all values.
     */
    function getAll(Set storage _obj) internal view returns (bytes32[] storage) {
        return _obj.list;
    }
}

contract ACL is IACL, IACLConstants {
    using Assignments for Assignments.Context;
    using Bytes32 for Bytes32.Set;

    mapping(bytes32 => Assignments.Context) private assignments;
    mapping(bytes32 => Bytes32.Set) private assigners;
    mapping(bytes32 => Bytes32.Set) private roleToGroups;
    mapping(bytes32 => Bytes32.Set) private groupToRoles;
    mapping(address => Bytes32.Set) private userContexts;

    mapping(uint256 => bytes32) public contexts;
    mapping(bytes32 => bool) public isContext;
    uint256 public numContexts;

    bytes32 public adminRole;
    bytes32 public adminRoleGroup;
    bytes32 public systemContext;

    modifier assertIsAdmin() {
        require(isAdmin(msg.sender), "unauthorized - must be admin");
        _;
    }

    modifier assertIsAssigner(
        bytes32 _context,
        address _addr,
        bytes32 _role
    ) {
        uint256 ca = canAssign(_context, msg.sender, _addr, _role);
        require(ca != CANNOT_ASSIGN && ca != CANNOT_ASSIGN_USER_NOT_APPROVED, "unauthorized");
        _;
    }

    modifier assertIsRoleGroup(bytes32 _roleGroup) {
        require(isRoleGroup(_roleGroup), "must be role group");
        _;
    }

    constructor(bytes32 _adminRole, bytes32 _adminRoleGroup) {
        adminRole = _adminRole;
        adminRoleGroup = _adminRoleGroup;
        systemContext = keccak256(abi.encodePacked(address(this)));

        // setup admin rolegroup
        bytes32[] memory roles = new bytes32[](1);
        roles[0] = _adminRole;
        _setRoleGroup(adminRoleGroup, roles);

        // set creator as admin
        _assignRole(systemContext, msg.sender, _adminRole);
    }

    // Admins

    function isAdmin(address _addr) public view override returns (bool) {
        return hasRoleInGroup(systemContext, _addr, adminRoleGroup);
    }

    function addAdmin(address _addr) public override {
        assignRole(systemContext, _addr, adminRole);
    }

    function removeAdmin(address _addr) public override {
        unassignRole(systemContext, _addr, adminRole);
    }

    // Contexts

    function getNumContexts() public view override returns (uint256) {
        return numContexts;
    }

    function getContextAtIndex(uint256 _index) public view override returns (bytes32) {
        return contexts[_index];
    }

    function getNumUsersInContext(bytes32 _context) public view override returns (uint256) {
        return assignments[_context].getNumUsers();
    }

    function getUserInContextAtIndex(bytes32 _context, uint256 _index) public view override returns (address) {
        return assignments[_context].getUserAtIndex(_index);
    }

    // Users

    function getNumContextsForUser(address _addr) public view override returns (uint256) {
        return userContexts[_addr].size();
    }

    function getContextForUserAtIndex(address _addr, uint256 _index) public view override returns (bytes32) {
        return userContexts[_addr].get(_index);
    }

    function userSomeHasRoleInContext(bytes32 _context, address _addr) public view override returns (bool) {
        return userContexts[_addr].has(_context);
    }

    // Role groups

    function hasRoleInGroup(
        bytes32 _context,
        address _addr,
        bytes32 _roleGroup
    ) public view override returns (bool) {
        return hasAnyRole(_context, _addr, groupToRoles[_roleGroup].getAll());
    }

    function setRoleGroup(bytes32 _roleGroup, bytes32[] memory _roles) public override assertIsAdmin {
        _setRoleGroup(_roleGroup, _roles);
    }

    function getRoleGroup(bytes32 _roleGroup) public view override returns (bytes32[] memory) {
        return groupToRoles[_roleGroup].getAll();
    }

    function isRoleGroup(bytes32 _roleGroup) public view override returns (bool) {
        return getRoleGroup(_roleGroup).length > 0;
    }

    function getRoleGroupsForRole(bytes32 _role) public view override returns (bytes32[] memory) {
        return roleToGroups[_role].getAll();
    }

    // Roles

    function hasRole(
        bytes32 _context,
        address _addr,
        bytes32 _role
    ) public view override returns (uint256) {
        if (assignments[_context].hasRoleForUser(_role, _addr)) {
            return HAS_ROLE_CONTEXT;
        } else if (assignments[systemContext].hasRoleForUser(_role, _addr)) {
            return HAS_ROLE_SYSTEM_CONTEXT;
        } else {
            return DOES_NOT_HAVE_ROLE;
        }
    }

    function hasAnyRole(
        bytes32 _context,
        address _addr,
        bytes32[] memory _roles
    ) public view override returns (bool) {
        bool hasAny = false;

        for (uint256 i = 0; i < _roles.length; i++) {
            if (hasRole(_context, _addr, _roles[i]) != DOES_NOT_HAVE_ROLE) {
                hasAny = true;
                break;
            }
        }

        return hasAny;
    }

    /**
     * @dev assign a role to an address
     */
    function assignRole(
        bytes32 _context,
        address _addr,
        bytes32 _role
    ) public override assertIsAssigner(_context, _addr, _role) {
        _assignRole(_context, _addr, _role);
    }

    /**
     * @dev remove a role from an address
     */
    function unassignRole(
        bytes32 _context,
        address _addr,
        bytes32 _role
    ) public override assertIsAssigner(_context, _addr, _role) {
        if (assignments[_context].hasRoleForUser(_role, _addr)) {
            assignments[_context].removeRoleForUser(_role, _addr);
        }

        // update user's context list?
        if (!assignments[_context].hasUser(_addr)) {
            userContexts[_addr].remove(_context);
        }

        emit RoleUnassigned(_context, _addr, _role);
    }

    function getRolesForUser(bytes32 _context, address _addr) public view override returns (bytes32[] memory) {
        return assignments[_context].getRolesForUser(_addr);
    }

    function getUsersForRole(bytes32 _context, bytes32 _role) public view override returns (address[] memory) {
        return assignments[_context].getUsersForRole(_role);
    }

    // Role assigners

    function addAssigner(bytes32 _roleToAssign, bytes32 _assignerRoleGroup) public override assertIsAdmin assertIsRoleGroup(_assignerRoleGroup) {
        assigners[_roleToAssign].add(_assignerRoleGroup);
        emit AssignerAdded(_roleToAssign, _assignerRoleGroup);
    }

    function removeAssigner(bytes32 _roleToAssign, bytes32 _assignerRoleGroup) public override assertIsAdmin assertIsRoleGroup(_assignerRoleGroup) {
        assigners[_roleToAssign].remove(_assignerRoleGroup);
        emit AssignerRemoved(_roleToAssign, _assignerRoleGroup);
    }

    function getAssigners(bytes32 _role) public view override returns (bytes32[] memory) {
        return assigners[_role].getAll();
    }

    function canAssign(
        bytes32 _context,
        address _assigner,
        address _assignee,
        bytes32 _role
    ) public view override returns (uint256) {
        // if they are an admin
        if (isAdmin(_assigner)) {
            return CAN_ASSIGN_IS_ADMIN;
        }

        // if they are assigning within their own context
        if (_context == generateContextFromAddress(_assigner)) {
            return CAN_ASSIGN_IS_OWN_CONTEXT;
        }

        // at this point we need to confirm that the assignee is approved
        if (hasRole(systemContext, _assignee, ROLE_APPROVED_USER) == DOES_NOT_HAVE_ROLE) {
            return CANNOT_ASSIGN_USER_NOT_APPROVED;
        }

        // if they belong to an role group that can assign this role
        bytes32[] memory roleGroups = getAssigners(_role);

        for (uint256 i = 0; i < roleGroups.length; i++) {
            bytes32[] memory roles = getRoleGroup(roleGroups[i]);

            if (hasAnyRole(_context, _assigner, roles)) {
                return CAN_ASSIGN_HAS_ROLE;
            }
        }

        return CANNOT_ASSIGN;
    }

    function generateContextFromAddress(address _addr) public pure override returns (bytes32) {
        return keccak256(abi.encodePacked(_addr));
    }

    // Internal functions

    /**
     * @dev assign a role to an address
     */
    function _assignRole(
        bytes32 _context,
        address _assignee,
        bytes32 _role
    ) private {
        // record new context if necessary
        if (!isContext[_context]) {
            contexts[numContexts] = _context;
            isContext[_context] = true;
            numContexts++;
        }

        assignments[_context].addRoleForUser(_role, _assignee);

        // update user's context list
        userContexts[_assignee].add(_context);

        // only admin should be able to assign somebody in the system context
        if (_context == systemContext) {
            require(isAdmin(msg.sender), "only admin can assign role in system context");
        }

        emit RoleAssigned(_context, _assignee, _role);
    }

    function _setRoleGroup(bytes32 _roleGroup, bytes32[] memory _roles) private {
        // remove old roles
        bytes32[] storage oldRoles = groupToRoles[_roleGroup].getAll();

        for (uint256 i = 0; i < oldRoles.length; i += 1) {
            bytes32 r = oldRoles[i];
            roleToGroups[r].remove(_roleGroup);
        }

        groupToRoles[_roleGroup].clear();

        // set new roles
        for (uint256 i = 0; i < _roles.length; i += 1) {
            bytes32 r = _roles[i];
            roleToGroups[r].add(_roleGroup);
            groupToRoles[_roleGroup].add(r);
        }

        emit RoleGroupUpdated(_roleGroup);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

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
    function getUserInContextAtIndex(bytes32 _context, uint256 _index) external view returns (address);

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
    function hasRoleInGroup(
        bytes32 _context,
        address _addr,
        bytes32 _roleGroup
    ) external view returns (bool);

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
    function hasRole(
        bytes32 _context,
        address _addr,
        bytes32 _role
    ) external view returns (uint256);

    /**
     * @dev Get whether given address has any of the given roles in the given context.
     * @param _context Context name.
     * @param _addr Address.
     * @param _roles The role list.
     * @return true if so
     */
    function hasAnyRole(
        bytes32 _context,
        address _addr,
        bytes32[] calldata _roles
    ) external view returns (bool);

    /**
     * @dev Assign a role to the given address in the given context.
     * @param _context Context name.
     * @param _addr Address.
     * @param _role The role.
     */
    function assignRole(
        bytes32 _context,
        address _addr,
        bytes32 _role
    ) external;

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
    function unassignRole(
        bytes32 _context,
        address _addr,
        bytes32 _role
    ) external;

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
    function canAssign(
        bytes32 _context,
        address _assigner,
        address _assignee,
        bytes32 _role
    ) external view returns (uint256);

    // utility methods

    /**
     * @dev Generate the context name which represents the given address.
     *
     * @param _addr Address.
     * @return context name.
     */
    function generateContextFromAddress(address _addr) external pure returns (bytes32);

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
pragma solidity >=0.8.9;

/**
 * @dev ACL Constants.
 */
abstract contract IACLConstants {
    // BEGIN: Generated by script outputConstants.js
    // DO NOT MANUALLY MODIFY THESE VALUES!
    bytes32 public constant ROLE_APPROVED_USER = 0x9c259f9342405d034b902fd5e1bba083f008e305ea4eb6a0dce9ac9a6256b63a;
    bytes32 public constant ROLE_PENDING_UNDERWRITER = 0xad56f8a5432d383c3e2c11b7b248f889e6ec544090486b3623f0f4ae1fad763b;
    bytes32 public constant ROLE_PENDING_BROKER = 0x3bd41a6d84c7de1e9d18694bd113405090439b9e32d5ab69d575821d513d83b5;
    bytes32 public constant ROLE_PENDING_INSURED_PARTY = 0x052b977cd6067e43b9140f08c53a22b88418f4d3ab7bd811716130d5a20cd8a3;
    bytes32 public constant ROLE_PENDING_CLAIMS_ADMIN = 0x325a96ceff51ae6b22de25dd7b4c8b9532dddf936add8ef16fc99219ff666a84;
    bytes32 public constant ROLE_UNDERWRITER = 0x8858a0dfcbfa158449ee0a3b5dae898cecc0746569152b05bbab9526bcc16864;
    bytes32 public constant ROLE_CAPITAL_PROVIDER = 0x428fa9969c6b3fab7bbdac20b73706f1f670a386be0a76d4060c185898b2aa22;
    bytes32 public constant ROLE_BROKER = 0x2623111b4a77e415ab5147aeb27da976c7a27950b6ec4022b4b9e77176266992;
    bytes32 public constant ROLE_INSURED_PARTY = 0x737de6bdef2e959d9f968f058e3e78b7365d4eda8e4023ecac2d51e3dbfb1401;
    bytes32 public constant ROLE_CLAIMS_ADMIN = 0x391db9b692991836c38aedfd24d7f4c9837739d4ee0664fe4ee6892a51e025a7;
    bytes32 public constant ROLE_ENTITY_ADMIN = 0x0922a3d5a8713fcf92ec8607b882fd2fcfefd8552a3c38c726d96fcde8b1d053;
    bytes32 public constant ROLE_ENTITY_MANAGER = 0xcfd13d23f7313d54f3a6d98c505045c58749561dd04531f9f2422a8818f0c5f8;
    bytes32 public constant ROLE_ENTITY_REP = 0xcca1ad0e9fb374bbb9dc3d0cbfd073ef01bd1d01d5a35bd0a93403fbee64318d;
    bytes32 public constant ROLE_POLICY_OWNER = 0x7f7cc8b2bac31c0e372310212be653d159f17ff3c41938a81446553db842afb6;
    bytes32 public constant ROLE_POLICY_CREATOR = 0x1d60d7146dec74c1b1a9dc17243aaa3b56533f607c16a718bcd78d8d852d6e52;
    bytes32 public constant ROLE_SYSTEM_ADMIN = 0xd708193a9c8f5fbde4d1c80a1e6f79b5f38a27f85ca86eccac69e5a899120ead;
    bytes32 public constant ROLE_SYSTEM_MANAGER = 0x807c518efb8285611b15c88a7701e4f40a0e9a38ce3e59946e587a8932410af8;
    bytes32 public constant ROLEGROUP_APPROVED_USERS = 0x9c687089ee5ebd0bc2ba9c954ebc7a0304b4046890b9064e5742c8c6c7afeab2;
    bytes32 public constant ROLEGROUP_CAPITAL_PROVIDERS = 0x2db57b52c5f263c359ba92194f5590b4a7f5fc1f1ca02f10cea531182851fe28;
    bytes32 public constant ROLEGROUP_POLICY_CREATORS = 0xdd53f360aa973c3daf7ff269398ced1ce7713d025c750c443c2abbcd89438f83;
    bytes32 public constant ROLEGROUP_BROKERS = 0x8d632412946eb879ebe5af90230c7db3f6d17c94c0ecea207c97e15fa9bb77c5;
    bytes32 public constant ROLEGROUP_INSURED_PARTYS = 0x65d0db34d07de31cfb8ca9f95dabc0463ce6084a447abb757f682f36ae3682e3;
    bytes32 public constant ROLEGROUP_CLAIMS_ADMINS = 0x5c7c2bcb0d2dfef15c423063aae2051d462fcd269b5e9b8c1733b3211e17bc8a;
    bytes32 public constant ROLEGROUP_ENTITY_ADMINS = 0x251766d8c7c7a6b927647b0f20c99f490db1c283eb0c482446085aaaa44b5e73;
    bytes32 public constant ROLEGROUP_ENTITY_MANAGERS = 0xa33a59233069411012cc12aa76a8a426fe6bd113968b520118fdc9cb6f49ae30;
    bytes32 public constant ROLEGROUP_ENTITY_REPS = 0x610cf17b5a943fc722922fc6750fb40254c24c6b0efd32554aa7c03b4ca98e9c;
    bytes32 public constant ROLEGROUP_POLICY_OWNERS = 0xc59d706f362a04b6cf4757dd3df6eb5babc7c26ab5dcc7c9c43b142f25da10a5;
    bytes32 public constant ROLEGROUP_SYSTEM_ADMINS = 0xab789755f97e00f29522efbee9df811265010c87cf80f8fd7d5fc5cb8a847956;
    bytes32 public constant ROLEGROUP_SYSTEM_MANAGERS = 0x7c23ac65f971ee875d4a6408607fabcb777f38cf73b3d6d891648646cee81f05;
    bytes32 public constant ROLEGROUP_TRADERS = 0x9f4d1dc1107c7d9d9f533f41b5aa5dbbb3b830e3b597338a8aee228ab083eb3a;
    bytes32 public constant ROLEGROUP_UNDERWRITERS = 0x18ecf8d2173ca8a5766fd7dde3bdb54017dc5413dc07cd6ba1785b63e9c62b82;
    // END: Generated by script outputConstants.js

    // used by canAssign() method
    uint256 public constant CANNOT_ASSIGN = 0;
    uint256 public constant CANNOT_ASSIGN_USER_NOT_APPROVED = 100;
    uint256 public constant CAN_ASSIGN_IS_ADMIN = 1;
    uint256 public constant CAN_ASSIGN_IS_OWN_CONTEXT = 2;
    uint256 public constant CAN_ASSIGN_HAS_ROLE = 3;

    // used by hasRole() method
    uint256 public constant DOES_NOT_HAVE_ROLE = 0;
    uint256 public constant HAS_ROLE_CONTEXT = 1;
    uint256 public constant HAS_ROLE_SYSTEM_CONTEXT = 2;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;
import "./IACL.sol";

interface IAccessControl {
    /**
     * @dev Check if given address has admin privileges.
     * @param _addr Address to check.
     * @return true if so
     */
    function isAdmin(address _addr) external view returns (bool);

    /**
     * @dev Check if given address has a role in the given role group in the current context.
     * @param _addr Address to check.
     * @param _roleGroup Rolegroup to check against.
     * @return true if so
     */
    function inRoleGroup(address _addr, bytes32 _roleGroup) external view returns (bool);

    /**
     * @dev Check if given address has a role in the given rolegroup in the given context.
     * @param _ctx Context to check against.
     * @param _addr Address to check.
     * @param _roleGroup Role group to check against.
     * @return true if so
     */
    function inRoleGroupWithContext(
        bytes32 _ctx,
        address _addr,
        bytes32 _roleGroup
    ) external view returns (bool);

    /**
     * @dev Get ACL reference.
     * @return ACL reference.
     */
    function acl() external view returns (IACL);

    /**
     * @dev Get current ACL context.
     * @return the context.
     */
    function aclContext() external view returns (bytes32);
}