// SPDX-License-Identifier: MIT
// Audit: https://hackmd.io/@devtooligan/YieldEmergencyBrakeSecurityReview2022-10-11

pragma solidity ^0.8.0;
import "../access/AccessControl.sol";
import "../interfaces/IEmergencyBrake.sol";


/// @dev EmergencyBrake allows to plan for and execute transactions that remove access permissions for a user
/// contract. In an permissioned environment this can be used for pausing components.
/// All contracts in scope of emergency plans must grant ROOT permissions to EmergencyBrake. To mitigate the risk
/// of governance capture, EmergencyBrake has very limited functionality, being able only to revoke existing roles
/// and to restore previously revoked roles. Thus EmergencyBrake cannot grant permissions that weren't there in the 
/// first place. As an additional safeguard, EmergencyBrake cannot revoke or grant ROOT roles.
contract EmergencyBrake is AccessControl, IEmergencyBrake {

    event Added(address indexed user, Permission permissionIn);
    event Removed(address indexed user, Permission permissionOut);
    event Executed(address indexed user);
    event Restored(address indexed user);

    uint256 public constant NOT_FOUND = type(uint256).max;

    mapping (address => Plan) public plans;

    constructor(address governor, address planner, address executor) AccessControl() {
        _grantRole(IEmergencyBrake.execute.selector, executor);
        _grantRole(IEmergencyBrake.add.selector, planner);
        _grantRole(IEmergencyBrake.remove.selector, planner);
        _grantRole(IEmergencyBrake.cancel.selector, planner);
        _grantRole(IEmergencyBrake.add.selector, governor);
        _grantRole(IEmergencyBrake.remove.selector, governor);
        _grantRole(IEmergencyBrake.cancel.selector, governor);
        _grantRole(IEmergencyBrake.execute.selector, governor);
        _grantRole(IEmergencyBrake.restore.selector, governor);
        _grantRole(IEmergencyBrake.terminate.selector, governor);
        // Granting roles (add, remove, cancel, execute, restore, terminate) is reserved to ROOT
    }

    /// @dev Is a plan executed?
    /// @param user address with auth privileges on permission hosts
    function executed(address user) external view override returns (bool) {
        return plans[user].executed;
    }

    /// @dev Does a plan contain a permission?
    /// @param user address with auth privileges on permission hosts
    /// @param permission permission that is being queried about
    function contains(address user, Permission calldata permission) external view override returns (bool) {
        return plans[user].permissions[_permissionToId(permission)].signature != bytes4(0);
    }

    /// @dev Return a permission by index
    /// @param user address with auth privileges on permission hosts
    /// @param idx permission index that is being queried about
    function permissionAt(address user, uint idx) external view override returns (Permission memory) {
        Plan storage plan_ = plans[user];
        return plan_.permissions[plan_.ids[idx]];
    }

    /// @dev Index of a permission in a plan. Returns type(uint256).max if not present.
    /// @param user address with auth privileges on permission hosts
    /// @param permission permission that is being queried about
    function index(address user, Permission calldata permission) external view override returns (uint) {
        Plan storage plan_ = plans[user];
        uint length = uint(plan_.ids.length);

        bytes32 id = _permissionToId(permission);

        for (uint i = 0; i < length; ++i ) {
            if (plan_.ids[i] == id) {
                return i;
            }
        }
        return NOT_FOUND;
    }

    /// @dev Number of permissions in a plan
    /// @param user address with auth privileges on permission hosts
    function total(address user) external view returns (uint) {
        return uint(plans[user].ids.length);
    }

    /// @dev Add permissions to an isolation plan
    /// @param user address with auth privileges on permission hosts
    /// @param permissionsIn permissions that are being added to an existing plan
    function add(address user, Permission[] calldata permissionsIn)
        external override auth 
    {   
        Plan storage plan_ = plans[user];
        require(!plan_.executed, "Plan in execution");

        uint length = permissionsIn.length;
        for (uint i; i < length; ++i) {
            Permission memory permissionIn = permissionsIn[i];
            require(permissionIn.signature != ROOT, "Can't remove ROOT");

            require(
                AccessControl(permissionIn.host).hasRole(permissionIn.signature, user),
                "Permission not found"
            ); // You don't want to find out execute reverts when you need it

            require(
                AccessControl(permissionIn.host).hasRole(ROOT, address(this)),
                "Need ROOT on host"
            ); // You don't want to find out you don't have ROOT while executing

            bytes32 idIn = _permissionToId(permissionIn);
            require(plan_.permissions[idIn].signature == bytes4(0), "Permission already set");

            plan_.permissions[idIn] = permissionIn; // Set the permission
            plan_.ids.push(idIn);

            emit Added(user, permissionIn);
        }

    }

    /// @dev Remove permissions from an isolation plan
    /// @param user address with auth privileges on permission hosts
    /// @param permissionsOut permissions that are being removed from an existing plan
    function remove(address user, Permission[] calldata permissionsOut) 
        external override auth
    {   
        Plan storage plan_ = plans[user];
        require(!plan_.executed, "Plan in execution");

        uint length = permissionsOut.length;
        for (uint i; i < length; ++i) {
            Permission memory permissionOut = permissionsOut[i];
            bytes32 idOut = _permissionToId(permissionOut);
            require(plan_.permissions[idOut].signature != bytes4(0), "Permission not found");

            delete plan_.permissions[idOut]; // Remove the permission
            
            // Loop through the ids array, copy the last item on top of the removed permission, then pop.
            uint last = uint(plan_.ids.length) - 1; // Length should be at least one at this point.
            for (uint j = 0; j <= last; ++j ) {
                if (plan_.ids[j] == idOut) {
                    if (j != last) plan_.ids[j] = plan_.ids[last];
                    plan_.ids.pop(); // Remove the id
                    break;
                }
            }

            emit Removed(user, permissionOut);
        }
    }

    /// @dev Remove a planned isolation plan
    /// @param user address with an isolation plan
    function cancel(address user)
        external override auth
    {
        Plan storage plan_ = plans[user];
        require(plan_.ids.length > 0, "Plan not found");
        require(!plan_.executed, "Plan in execution");

        _erase(user);
    }

    /// @dev Remove the restoring option from an isolated user
    /// @param user address with an isolation plan
    function terminate(address user)
        external override auth
    {
        Plan storage plan_ = plans[user];
        require(plan_.executed, "Plan not in execution");
        // If the plan is executed, then it must exist
        _erase(user);
    }

    /// @dev Remove all data related to an user
    /// @param user address with an isolation plan
    function _erase(address user)
        internal
    {
        Plan storage plan_ = plans[user];

        // Loop through the plan, and remove permissions and ids.
        uint length = uint(plan_.ids.length);

        // First remove the permissions
        for (uint i = length; i > 0; --i ) {
            bytes32 id = plan_.ids[i - 1];
            emit Removed(user, plan_.permissions[id]);
            delete plan_.permissions[id];
            plan_.ids.pop();
        }

        delete plans[user];
    }


    /// @dev Check if a plan is valid for execution
    /// @param user address with an isolation plan
    function check(address user)
        external view override returns (bool)
    {
        Plan storage plan_ = plans[user];

        // Loop through the ids array, and check all roles.
        uint length = uint(plan_.ids.length);
        require(length > 0, "Plan not found");

        for (uint i = 0; i < length; ++i ) {
            bytes32 id = plan_.ids[i];
            Permission memory permission_ = plan_.permissions[id]; 
            AccessControl host = AccessControl(permission_.host);

            if (!host.hasRole(permission_.signature, user)) return false;
        }

        return true;
    }

    /// @dev Execute an access removal transaction
    /// @notice The plan needs to be kept up to date with the current permissioning, or it will revert.
    /// @param user address with an isolation plan
    function execute(address user)
        external override auth
    {
        Plan storage plan_ = plans[user];
        require(!plan_.executed, "Already executed");
        plan_.executed = true;

        // Loop through the ids array, and revoke all roles.
        uint length = uint(plan_.ids.length);
        require(length > 0, "Plan not found");

        for (uint i = 0; i < length; ++i ) {
            bytes32 id = plan_.ids[i];
            Permission memory permission_ = plan_.permissions[id]; 
            AccessControl host = AccessControl(permission_.host);

            // `revokeRole` won't revert if the role is not granted, but we need
            // to revert because otherwise operators with `execute` and `restore`
            // permissions will be able to restore removed roles if the plan is not
            // updated to reflect the removed roles.
            // By reverting, a plan that is not up to date will revert on execution,
            // but that seems like a lesser evil versus allowing operators to override
            // governance decisions.
            require(
                host.hasRole(permission_.signature, user),
                "Permission not found"
            );
            host.revokeRole(permission_.signature, user);
        }

        emit Executed(user);
    }

    /// @dev Restore the orchestration from an isolated user
    function restore(address user)
        external override auth
    {
        Plan storage plan_ = plans[user];
        require(plan_.executed, "Plan not executed");
        plan_.executed = false;

        // Loop through the ids array, and grant all roles.
        uint length = uint(plan_.ids.length);

        for (uint i = 0; i < length; ++i ) {
            bytes32 id = plan_.ids[i];
            Permission memory permission_ = plan_.permissions[id]; 
            AccessControl host = AccessControl(permission_.host);
            bytes4 signature_ = permission_.signature;
            host.grantRole(signature_, user);
        }

        emit Restored(user);
    }


    /// @dev used to calculate the id of a Permission so it can be indexed within a Plan
    /// @param permission a permission, containing a host address and a function signature
    function permissionToId(Permission calldata permission)
        external pure returns(bytes32 id)
    {
        id = _permissionToId(permission);
    }

    /// @dev used to recreate a Permission from it's id
    /// @param id the key used for indexing a Permission within a Plan
    function idToPermission(bytes32 id)
        external pure returns(Permission memory permission) 
    {
        permission = _idToPermission(id);
    }

    function _permissionToId(Permission memory permission) 
        internal pure returns(bytes32 id) 
    {
        id = bytes32(abi.encodePacked(permission.signature, permission.host));
    }

    function _idToPermission(bytes32 id) 
        internal pure returns(Permission memory permission)
    {
        address host = address(bytes20(id));
        bytes4 signature = bytes4(id << 160);
        permission = Permission(host, signature);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes4` identifier. These are expected to be the 
 * signatures for all the functions in the contract. Special roles should be exposed
 * in the external API and be unique:
 *
 * ```
 * bytes4 public constant ROOT = 0x00000000;
 * ```
 *
 * Roles represent restricted access to a function call. For that purpose, use {auth}:
 *
 * ```
 * function foo() public auth {
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `ROOT`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {setRoleAdmin}.
 *
 * WARNING: The `ROOT` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
contract AccessControl {
    struct RoleData {
        mapping (address => bool) members;
        bytes4 adminRole;
    }

    mapping (bytes4 => RoleData) private _roles;

    bytes4 public constant ROOT = 0x00000000;
    bytes4 public constant ROOT4146650865 = 0x00000000; // Collision protection for ROOT, test with ROOT12007226833()
    bytes4 public constant LOCK = 0xFFFFFFFF;           // Used to disable further permissioning of a function
    bytes4 public constant LOCK8605463013 = 0xFFFFFFFF; // Collision protection for LOCK, test with LOCK10462387368()

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role
     *
     * `ROOT` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes4 indexed role, bytes4 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call.
     */
    event RoleGranted(bytes4 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes4 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Give msg.sender the ROOT role and create a LOCK role with itself as the admin role and no members. 
     * Calling setRoleAdmin(msg.sig, LOCK) means no one can grant that msg.sig role anymore.
     */
    constructor () {
        _grantRole(ROOT, msg.sender);   // Grant ROOT to msg.sender
        _setRoleAdmin(LOCK, LOCK);      // Create the LOCK role by setting itself as its own admin, creating an independent role tree
    }

    /**
     * @dev Each function in the contract has its own role, identified by their msg.sig signature.
     * ROOT can give and remove access to each function, lock any further access being granted to
     * a specific action, or even create other roles to delegate admin control over a function.
     */
    modifier auth() {
        require (_hasRole(msg.sig, msg.sender), "Access denied");
        _;
    }

    /**
     * @dev Allow only if the caller has been granted the admin role of `role`.
     */
    modifier admin(bytes4 role) {
        require (_hasRole(_getRoleAdmin(role), msg.sender), "Only admin");
        _;
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes4 role, address account) external view returns (bool) {
        return _hasRole(role, account);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes4 role) external view returns (bytes4) {
        return _getRoleAdmin(role);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.

     * If ``role``'s admin role is not `adminRole` emits a {RoleAdminChanged} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function setRoleAdmin(bytes4 role, bytes4 adminRole) external virtual admin(role) {
        _setRoleAdmin(role, adminRole);
    }

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
    function grantRole(bytes4 role, address account) external virtual admin(role) {
        _grantRole(role, account);
    }

    
    /**
     * @dev Grants all of `role` in `roles` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - For each `role` in `roles`, the caller must have ``role``'s admin role.
     */
    function grantRoles(bytes4[] memory roles, address account) external virtual {
        for (uint256 i = 0; i < roles.length; i++) {
            require (_hasRole(_getRoleAdmin(roles[i]), msg.sender), "Only admin");
            _grantRole(roles[i], account);
        }
    }

    /**
     * @dev Sets LOCK as ``role``'s admin role. LOCK has no members, so this disables admin management of ``role``.

     * Emits a {RoleAdminChanged} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function lockRole(bytes4 role) external virtual admin(role) {
        _setRoleAdmin(role, LOCK);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes4 role, address account) external virtual admin(role) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes all of `role` in `roles` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - For each `role` in `roles`, the caller must have ``role``'s admin role.
     */
    function revokeRoles(bytes4[] memory roles, address account) external virtual {
        for (uint256 i = 0; i < roles.length; i++) {
            require (_hasRole(_getRoleAdmin(roles[i]), msg.sender), "Only admin");
            _revokeRole(roles[i], account);
        }
    }

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
    function renounceRole(bytes4 role, address account) external virtual {
        require(account == msg.sender, "Renounce only for self");

        _revokeRole(role, account);
    }

    function _hasRole(bytes4 role, address account) internal view returns (bool) {
        return _roles[role].members[account];
    }

    function _getRoleAdmin(bytes4 role) internal view returns (bytes4) {
        return _roles[role].adminRole;
    }

    function _setRoleAdmin(bytes4 role, bytes4 adminRole) internal virtual {
        if (_getRoleAdmin(role) != adminRole) {
            _roles[role].adminRole = adminRole;
            emit RoleAdminChanged(role, adminRole);
        }
    }

    function _grantRole(bytes4 role, address account) internal {
        if (!_hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, msg.sender);
        }
    }

    function _revokeRole(bytes4 role, address account) internal {
        if (_hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, msg.sender);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface IEmergencyBrake {
    struct Plan {
        bool executed;
        mapping(bytes32 => Permission) permissions;
        bytes32[] ids;
    }

    struct Permission {
        address host;
        bytes4 signature;
    }

    function executed(address user) external view returns (bool);
    function contains(address user, Permission calldata permission) external view returns (bool);
    function permissionAt(address user, uint idx) external view returns (Permission memory);
    function index(address user, Permission calldata permission) external view returns (uint index_);

    function add(address user, Permission[] calldata permissionsIn) external;
    function remove(address user, Permission[] calldata permissionsOut) external;
    function cancel(address user) external;
    function check(address user) external view returns (bool);
    function execute(address user) external;
    function restore(address user) external;
    function terminate(address user) external;
}