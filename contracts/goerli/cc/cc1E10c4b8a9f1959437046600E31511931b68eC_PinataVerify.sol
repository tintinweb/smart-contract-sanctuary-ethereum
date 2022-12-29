// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

error PinataVerify__NoApproval(address approvedFrom, address approvedTo);

contract PinataVerify {
    enum PermissionLevel {
        None,
        Read,
        Write,
        Owner
    }

    event giveApproval(
        address indexed approvedFrom,
        address indexed approvedTo,
        PermissionLevel permissionLevel
    );

    event dataUpload(address indexed uploadedFrom, address indexed approvedFrom, string ipfsHash);

    mapping(address => mapping(address => PermissionLevel)) private s_approvals;
    mapping(address => mapping(address => string)) private s_uploads;

    modifier isApproved(address approvedFrom) {
        PermissionLevel permissionLevel = s_approvals[approvedFrom][msg.sender];

        if (permissionLevel == PermissionLevel.None) {
            revert PinataVerify__NoApproval(approvedFrom, msg.sender);
        }
        _;
    }

    function grantPermission(address approvedTo, PermissionLevel permissionLevel) public {
        require(
            approvedTo != msg.sender,
            "Uploader and the address to grant access should be different"
        );
        s_approvals[msg.sender][approvedTo] = permissionLevel;
        emit giveApproval(msg.sender, approvedTo, permissionLevel);
    }

    function uploadData(
        address approvedFrom,
        string memory data
    ) external isApproved(approvedFrom) {
        s_uploads[msg.sender][approvedFrom] = data;
        emit dataUpload(msg.sender, approvedFrom, data);
    }

    function checkGivenPermission(address approvedTo) public view returns (PermissionLevel) {
        return s_approvals[msg.sender][approvedTo];
    }

    function checkReceivedPermission(address approvedFrom) public view returns (PermissionLevel) {
        return s_approvals[approvedFrom][msg.sender];
    }

    function checkUploads(address approvedFrom) public view returns (string memory) {
        return s_uploads[msg.sender][approvedFrom];
    }
}

/////////////////////////////////////////////////////////
////////////////////NEEDED FUNCTIONS/////////////////////
/////////////////////////////////////////////////////////
// CHECK ALL ADDRESSES + PERMISSIONLEVEL I GAVE PERMISSION
// CHECK ALL ADDRESSES + PERMISSIONLEVEL I RECEIVED PERMISSION