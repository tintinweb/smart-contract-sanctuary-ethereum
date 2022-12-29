// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
//A will call approve(address(B), 100)
//B will check how many tokens A gave him permission to use by calling allowance(address(A), address(B))
//B will send to his account these tokens by calling transferFrom(address(A), address(B), 100)

error PinataVerify__NoApproval(address approvedFrom, address approvedTo);

contract PinataVerify {
    enum PermissionLevel {
        None,
        Read,
        Write,
        Owner
    }
    struct Approval {
        address[] approvedToArray;
        PermissionLevel permissionLevel;
    }

    // ALLOWANCE TO USE MY DATA --> NFT, TOKENS AND MORE // Strafzettel/Rezepte über Blockchain

    // APPROVEDFROM --> APPROVEDTO
    mapping(address => Approval) private s_approvals;
    mapping(address => string) private s_uploads;

    function isAddressApproved(address approvedFrom) private view returns (bool) {
        Approval memory approval = s_approvals[approvedFrom];
        for (uint256 i = 0; i < approval.approvedToArray.length; i++) {
            if (approval.approvedToArray[i] == msg.sender) {
                return true;
            }
        }
        return false;
    }

    // MSG.SENDER gives permission to approvedTo
    function grantPermission(
        address approvedTo // PermissionLevel permissionLevel
    ) public {
        require(
            approvedTo != msg.sender,
            "Uploader and the address to grant access should be different"
        );
        s_approvals[msg.sender].approvedToArray.push(approvedTo);
        // s_approvals[msg.sender].approvedTo = permissionLevel;
    }

    // function concatenateAddresses(address _a, address _b)
    //     public
    //     pure
    //     returns (bytes)
    // {
    //     return abi.encodePacked(_a, _b);
    // }

    // function revokePermission(address _uploader) public {
    //     require(canGrantPermission[msg.sender], "You do not have permission to revoke permission");
    //     canUpload[_uploader] = false;
    // }

    // MSG.SENDER = DATA PRODUCER
    // MSG.SENDER MUST BE IN APPROVEDTOARRAY FROM APPROVEDFROM
    function uploadData(address approvedFrom, string memory data) public {
        bool isApproved = isAddressApproved(approvedFrom);

        if (!isApproved) {
            revert PinataVerify__NoApproval(approvedFrom, msg.sender);
        }
        // require(isApproved, "You do not have permission to upload data");
        s_uploads[msg.sender] = data;
        // Do something with the data here, such as storing it on the blockchain
    }

    // check to who i got allowance
    // function checkMyAllowance() public {
    //     return s_approvals[msg.sender];
    // }

    //
    // MSG.SENDER --> APPROVEDTO
    function checkGavenAllowance() public view returns (Approval memory) {
        return s_approvals[msg.sender];
    }

    function checkUploads() public view returns (string memory) {
        return s_uploads[msg.sender];
    }
}