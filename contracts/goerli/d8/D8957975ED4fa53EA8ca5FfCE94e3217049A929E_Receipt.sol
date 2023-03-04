// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

contract Receipt {
    // Struct representing an admin
    struct Admin {
        bool isSuperAdmin; // Whether the admin is a super admin
        bool exists; // Whether the admin exists
    }

    // Modifier that only allows super admins
    modifier onlySuperAdmin() {
        require(
            admins[msg.sender].isSuperAdmin,
            "Only super admin can perform this action"
        );
        _;
    }

    // Mapping from admin addresses to admin structs
    mapping(address => Admin) public admins;

    event AdminAdded(address indexed adminId);

    // Track for total admins
    address[] public adminKeys;

    constructor() {
        admins[msg.sender].isSuperAdmin = true;
        admins[msg.sender].exists = true;
        adminKeys.push(msg.sender);

        emit AdminAdded(msg.sender);
    }

    // Function to get a list of all admins (super admin only)
    function getAdmins() public view onlySuperAdmin returns (address[] memory) {
        address[] memory result = new address[](adminKeys.length);

        uint256 index = 0;
        for (uint256 i = 0; i < adminKeys.length; i++) {
            if (admins[adminKeys[i]].exists) {
                result[index] = adminKeys[i];
                index++;
            }
        }

        return result;
    }

    // Function to get a list of all admins (super admin only)
    function getAdmins2() public view returns (address[] memory, Admin memory) {
        address[] memory result = new address[](adminKeys.length);

        Admin storage admin = admins[msg.sender];

        uint256 index = 0;
        for (uint256 i = 0; i < adminKeys.length; i++) {
            if (admins[adminKeys[i]].exists) {
                result[index] = adminKeys[i];
                index++;
            }
        }

        return (result, admin);
    }
}