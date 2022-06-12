// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IAdmin.sol";

contract Admin is IAdmin {
    // Listing all admins
    address[] public admins;

    // Modifier for easier checking if user is admin
    mapping(address => bool) public isAdmin;

    // Modifier restricting access to only admin
    modifier onlyAdmin {
        require(isAdmin[msg.sender], "RF_ADMIN: Only admin can call.");
        _;
    }

    // Constructor to set initial admins during deployment
    constructor (address[] memory _admins) {
        for(uint i = 0; i < _admins.length; i++) {
            _addAdmin(_admins[i]);
        }
    }

    // // INITIALIZER
    // function _initialize(address [] memory _admins) external initializer {
    //     for(uint i = 0; i < _admins.length; i++) {
    //         _addAdmin(_admins[i]);
    //     }
    // }

    function addAdmin(address _adminAddress) override external onlyAdmin {
        _addAdmin(_adminAddress);
    }

    function _addAdmin(address _adminAddress) internal {
        // Can't add 0x address as an admin
        require(_adminAddress != address(0x0), "RF_ADMIN: Address 0 can not be an admin");
        // Can't add existing admin
        require(!isAdmin[_adminAddress], "RF_ADMIN: Admin already exists");
        // Add admin to array of admins
        admins.push(_adminAddress);
        // Set mapping
        isAdmin[_adminAddress] = true;
    }

    function removeAdmin(address _adminAddress) override external onlyAdmin {
        // Admin has to exist
        require(isAdmin[_adminAddress]);
        // Make sure at least 1 admin still excists
        require(admins.length > 1, "RF_ADMIN: Can not remove all admins since contract becomes unusable.");

        uint i = 0;
        while(admins[i] != _adminAddress) {
            if(i == admins.length) {
                revert("RF_ADMIN: Passed admin address does not exist");
            }
            i++;
        }

        // Copy the last admin position to the current index
        admins[i] = admins[admins.length-1];
        // Set admin mapping value of this admin as false
        isAdmin[_adminAddress] = false;
        // Remove the last admin, since it's double present
        admins.pop();
    }

    // Fetch all admins
    function getAllAdmins() override external view returns(address [] memory)
    {
        return admins;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAdmin {
    function isAdmin(address _user) external returns(bool _isAdmin);
    function addAdmin(address _adminAddress) external;
    function removeAdmin(address _adminAddress) external;
    function getAllAdmins() external view returns(address [] memory);
}