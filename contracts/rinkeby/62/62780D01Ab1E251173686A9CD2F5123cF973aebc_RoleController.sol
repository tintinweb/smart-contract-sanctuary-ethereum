/**
 *Submitted for verification at Etherscan.io on 2022-09-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

enum Role {
    OWNER,
    MINTER,
    BURNER,
    TRANSFERER,
    CALLER,
    CALL_HELPER,
    LAND_MANAGER
}

interface IRoleController {
    function isWhitelist(Role role, address sender)
        external
        view
        returns (bool);
}

contract RoleController is IRoleController {
    mapping(Role => mapping(address => bool)) public isWhitelist;

    event RoleSet(
        Role indexed role,
        address indexed assignee,
        bool isEnable,
        address indexed caller
    );

    constructor(address owner) {
        isWhitelist[Role.OWNER][owner] = true;
    }

    modifier onlyRole(Role role) {
        require(isWhitelist[role][msg.sender], "XRB: only whitelist");
        _;
    }

    function setRole(
        Role role,
        address assignee,
        bool isEnable
    ) external onlyRole(Role.OWNER) {
        isWhitelist[role][assignee] = isEnable;
        emit RoleSet(role, assignee, isEnable, msg.sender);
    }
}