// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

contract Receipt2 {
    // Struct representing an admin
    struct Admin {
        bool isSuperAdmin; // Whether the admin is a super admin
        bool exists; // Whether the admin exists
    }

    // Mapping from admin addresses to admin structs
    mapping(address => Admin) public admins;

    // Modifier that only allows super admins
    modifier onlySuperAdmin() {
        require(
            admins[msg.sender].isSuperAdmin,
            "Only super admin can perform this action"
        );
        _;
    }

    // Modifier that only allows  admins
    modifier onlyAdmin() {
        require(
            admins[msg.sender].exists,
            "Only admins can perform this action"
        );
        _;
    }

    constructor() {
        admins[msg.sender].isSuperAdmin = true;
        admins[msg.sender].exists = true;
    }

    // Function to get a list of all admins (super admin only)
    function superAdminCall()
        public
        view
        onlySuperAdmin
        returns (string memory, address, bool, bool)
    {
        Admin storage admin = admins[msg.sender];

        return (
            "Called Super Admin: ",
            msg.sender,
            admin.exists,
            admin.isSuperAdmin
        );
    }

    // Function to get a list of all admins (super admin only)
    function adminCall()
        public
        view
        onlyAdmin
        returns (string memory, address, bool, bool)
    {
        Admin storage admin = admins[msg.sender];

        return ("Called Admin: ", msg.sender, admin.exists, admin.isSuperAdmin);
    }

    // Open function see if current user is admin
    function openCall()
        public
        view
        returns (string memory, address, bool, bool)
    {
        Admin storage admin = admins[msg.sender];

        return ("Called Open", msg.sender, admin.exists, admin.isSuperAdmin);
    }

    // Add a new admin
    function addAdmin(
        address _adminId,
        bool _isSuperAdmin
    ) public onlySuperAdmin returns (address) {
        admins[_adminId].isSuperAdmin = _isSuperAdmin;
        admins[_adminId].exists = true;

        return _adminId;
    }

    // Add a new admin
    function removeAdmin(
        address _adminId
    ) public onlySuperAdmin returns (address) {
        admins[_adminId].isSuperAdmin = false;
        admins[_adminId].exists = false;

        return _adminId;
    }
}