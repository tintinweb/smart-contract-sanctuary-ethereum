/**
 *Submitted for verification at Etherscan.io on 2022-05-12
*/

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.5;
pragma abicoder v2;

contract TestImplementation {
    bytes32 role;
    bytes32 previousAdminRole;
    bytes32 newAdminRole;
    address account;
    address sender;

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

    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    function emitRoleAdminChanged() external {
        emit RoleAdminChanged(role, previousAdminRole, newAdminRole);
    }

    function emitRoleGranted() external {
        emit RoleGranted(role, account, sender);
    }

    function emitRoleRevoked() external {
        emit RoleRevoked(role, account, sender);
    }
}