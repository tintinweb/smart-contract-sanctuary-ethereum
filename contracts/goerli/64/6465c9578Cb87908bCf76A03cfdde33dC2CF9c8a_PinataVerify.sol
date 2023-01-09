// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

error PinataVerify__NoApproval(address approvedFrom, address approvedTo);
error PinataVerify__NotVerified(address approvedFrom, address approvedTo);

contract PinataVerify {
    enum PermissionLevel {
        None,
        Private,
        Public
    }

    struct DataUpload {
        string ipfsHash;
        string ipfsId;
        bool verified;
    }

    event giveApproval(
        address indexed approvedFrom,
        address indexed approvedTo,
        PermissionLevel permissionLevel
    );

    event dataUploadSuccess(
        address indexed uploadedFrom,
        address indexed approvedFrom,
        DataUpload dataUpload
    );

    event dataUploadVerified(
        address indexed uploadedFrom,
        address indexed approvedFrom,
        DataUpload dataUpload
    );

    mapping(address => mapping(address => PermissionLevel)) private s_approvals;
    mapping(address => mapping(address => DataUpload)) private s_uploads;

    modifier isApproved(address approvedFrom) {
        PermissionLevel permissionLevel = s_approvals[approvedFrom][msg.sender];

        if (permissionLevel == PermissionLevel.None) {
            revert PinataVerify__NoApproval(approvedFrom, msg.sender);
        }
        _;
    }

    modifier isVerified(address approvedTo) {
        PermissionLevel permissionLevel = s_approvals[msg.sender][approvedTo];
        if (permissionLevel == PermissionLevel.None) {
            revert PinataVerify__NotVerified(approvedTo, msg.sender);
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
        string memory ipfsHash,
        string memory ipfsId
    ) external isApproved(approvedFrom) {
        DataUpload memory dataUpload = DataUpload(ipfsHash, ipfsId, false);
        s_uploads[msg.sender][approvedFrom] = DataUpload(ipfsHash, ipfsId, false);
        emit dataUploadSuccess(msg.sender, approvedFrom, dataUpload);
    }

    function verifyDataUpload(
        address approvedTo,
        string memory signedIpfsHash
    ) external isVerified(approvedTo) {
        s_uploads[approvedTo][msg.sender].verified = true;
        s_uploads[approvedTo][msg.sender].ipfsHash = signedIpfsHash;
        DataUpload memory dataUpload = s_uploads[approvedTo][msg.sender];
        emit dataUploadVerified(approvedTo, msg.sender, dataUpload);
    }

    function checkGivenPermission(address approvedTo) public view returns (PermissionLevel) {
        return s_approvals[msg.sender][approvedTo];
    }

    function checkReceivedPermission(address approvedFrom) public view returns (PermissionLevel) {
        return s_approvals[approvedFrom][msg.sender];
    }

    function checkUploads(address approvedFrom) public view returns (DataUpload[2] memory) {
        return [s_uploads[msg.sender][approvedFrom], s_uploads[approvedFrom][msg.sender]];
    }
}

/////////////////////////////////////////////////////////
////////////////////NEEDED FUNCTIONS/////////////////////
/////////////////////////////////////////////////////////
// CHECK ALL ADDRESSES + PERMISSIONLEVEL I GAVE PERMISSION
// CHECK ALL ADDRESSES + PERMISSIONLEVEL I RECEIVED PERMISSION