// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "./interfaces/IAccessControl.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract AccessControl is Context, IAccessControl {
    mapping(bytes32 => RoleData) private _roles;

    bytes32 internal ADMIN_ROLE = keccak256("ADMIN");
    bytes32 internal LECTURER_ROLE = keccak256("LECTURER");
    bytes32 internal STUDENT_ROLE = keccak256("STUDENT");

    constructor() {
        _roles[ADMIN_ROLE].members[_msgSender()] = true;
        _roles[ADMIN_ROLE].role = ADMIN_ROLE;
        _roles[LECTURER_ROLE].role = LECTURER_ROLE;
        _roles[STUDENT_ROLE].role = STUDENT_ROLE;
    }

    modifier onlyRole(bytes32 role) {
        require(hasRole(role, _msgSender()), "You are not allowed");
        _;
    }

    modifier onlyRoleExist(bytes32 role) {
        require(getRoleExist(role) != bytes32(0), "Role isn't existed");
        _;
    }

    function hasRole(bytes32 role, address account)
        public
        view
        onlyRoleExist(role)
        returns (bool)
    {
        return _roles[role].members[account];
    }

    function getRoleExist(bytes32 role) public view returns (bytes32) {
        return _roles[role].role;
    }

    function grantRole(bytes32 role, address account)
        public
        onlyRoleExist(role)
        onlyRole(ADMIN_ROLE)
    {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function revokeRole(bytes32 role, address account)
        public
        virtual
        onlyRoleExist(role)
        onlyRole(ADMIN_ROLE)
    {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, _msgSender());
        }
    }

    function renounceRole(bytes32 role)
        public
        override
        onlyRole(getRoleExist(role))
    {
        if (hasRole(role, _msgSender())) {
            _roles[role].members[_msgSender()] = false;
            emit RoleRevoked(role, _msgSender());
        }
    }

    function addNewRoleAdmin(bytes32 role) public virtual onlyRole(ADMIN_ROLE) {
        require(getRoleExist(role) == bytes32(0));
        _roles[role].role = role;
        emit RoleAdminChanged(role, bytes32(0), role);
    }

    function removeNewRoleAdmin(bytes32 role)
        public
        virtual
        onlyRoleExist(role)
        onlyRole(ADMIN_ROLE)
    {
        require(role != ADMIN_ROLE);
        bytes32 previousAdminRole = getRoleExist(role);
        _roles[role].role = bytes32(0);
        emit RoleAdminChanged(role, previousAdminRole, role);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IAccessControl {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 role;
    }
    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );
    event RoleRevoked(bytes32 indexed role, address indexed account);

    function hasRole(bytes32 role, address account)
        external
        view
        returns (bool);

    function getRoleExist(bytes32 role) external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function renounceRole(bytes32 role) external;

    function addNewRoleAdmin(bytes32 role) external;

    function removeNewRoleAdmin(bytes32 role) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}