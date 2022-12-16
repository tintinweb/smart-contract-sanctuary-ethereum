/**
 *Submitted for verification at Etherscan.io on 2022-12-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;



contract AccessRegistry{
    // Maps signatory addresses to their access status (true = has access, false = no access)
    mapping(address => bool) public signatories;

    // The admin address that can manage the signatories
    address public admin;

    // The constructor sets the initial admin address
    constructor(address _admin) {
        admin = _admin;
    }

    // Only the admin can add or revoke access for a signatory
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only the admin can perform this action");
        _;
    }

    function hasAccess(address _a) external view returns(bool){
        return (signatories[_a]);
    }

    // Adds a signatory to the registry with access
    function addSignatory(address signatory) public onlyAdmin {
        signatories[signatory] = true;
    }

    // Revokes access for a signatory
    function revokeSignatory(address signatory) public onlyAdmin {
        signatories[signatory] = false;
    }

    // A signatory can renounce their access
    function renounceSignatory() public {
        require(signatories[msg.sender], "Signatory does not have access");
        delete signatories[msg.sender];
    }

    // The admin can transfer their admin privileges to a new address
    function transferAdmin(address newAdmin) public onlyAdmin {
        admin = newAdmin;
    }
}