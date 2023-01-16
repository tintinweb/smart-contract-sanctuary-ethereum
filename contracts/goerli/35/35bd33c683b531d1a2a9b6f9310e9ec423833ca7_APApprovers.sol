/**
 *Submitted for verification at Etherscan.io on 2023-01-16
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract APApprovers {

    
    struct Approverstruct {
        uint256 id;
        string approverName;
        bool active;
        uint256 approvalLevel;
        uint256[] vendorApprovalList;
        uint256 created;
        uint256 updated;
    }

    mapping(bytes32 => Approverstruct) private approversByName;
    mapping(uint256 => Approverstruct) private approversById;

    uint256 public totalEntries;

    

    function contructorFunction(uint256 _totalEntries) public {
        totalEntries = _totalEntries;
        
        // Create the default approver
        Approverstruct memory defaultApprover = Approverstruct({
            id: 0,
            approverName: "Blockchain Approver",
            active: true,
            approvalLevel: 10,
            vendorApprovalList: new uint256[](0),
            created: block.timestamp,
            updated: block.timestamp
        });
        totalEntries++;
        approversByName[
            keccak256(abi.encodePacked("Blockchain Approver"))
        ] = defaultApprover;
        approversById[0] = defaultApprover;
        
    }

    constructor() {}

    function addApprover(
        string memory _approverName,
        uint _approvalLevel,
        uint256[] memory _vendorApprovalList
    ) public returns (bool, string memory) {
        //Check that the approver does not already exist, if it does return false
        if (
            approversByName[keccak256(abi.encodePacked(_approverName))]
                .active == true
        ) {
            return (false, "Approver already exists");
        }

        //Create a new approver
        Approverstruct memory newApprover = Approverstruct({
            id: totalEntries,
            approverName: _approverName,
            active: true,
            approvalLevel: _approvalLevel,
            vendorApprovalList: _vendorApprovalList,
            created: block.timestamp,
            updated: block.timestamp
        });

        //Add the approver to the approversByName mapping
        approversByName[
            keccak256(abi.encodePacked(_approverName))
        ] = newApprover;

        //Add the approver to the approversById mapping

        approversById[totalEntries] = newApprover;

        //Increment the totalEntries
        totalEntries++;

        return (true, "Approver added");
    }

    function setApproverStatus(
        string memory _approverName,
        bool _enable
    ) public returns (bool, string memory) {
        for (uint256 i = 0; i < totalEntries; i++) {
            if (
                keccak256(abi.encodePacked(approversById[i].approverName)) ==
                keccak256(abi.encodePacked(_approverName))
            ) {
                approversById[i].active = _enable;
                approversById[i].updated = block.timestamp;
                if (_enable) {
                    return (true, "Approver enabled");
                } else {
                    return (true, "Approver disabled");
                }
            }
        }
        return (false, "Approver not found");
    }

    function getAllApprovers() public view returns (Approverstruct[] memory) {
        Approverstruct[] memory allApprovers = new Approverstruct[](
            totalEntries
        );

        for (uint256 i = 0; i < totalEntries; i++) {
            allApprovers[i] = approversById[i];
        }
        return allApprovers;
    }

    function getNumberOfApprovers() public view returns (uint256) {
        return totalEntries;
    }

    function addVendorToApprover(
        string memory _approverName,
        uint256 _vendorId
    ) public returns (bool, string memory) {
        for (uint256 i = 0; i < totalEntries; i++) {
            if (
                keccak256(abi.encodePacked(approversById[i].approverName)) ==
                keccak256(abi.encodePacked(_approverName))
            ) {
                for (
                    uint256 j = 0;
                    j < approversById[i].vendorApprovalList.length;
                    j++
                ) {
                    if (approversById[i].vendorApprovalList[j] == _vendorId) {
                        return (false, "Vendor already exists");
                    }
                }
                approversById[i].vendorApprovalList.push(_vendorId);
                approversById[i].updated = block.timestamp;
                return (true, "Vendor added");
            }
        }
        return (false, "Approver not found");
    }

    function removeVendorFromApprover(
        string memory _approverName,
        uint256 _vendorId
    ) public returns (bool, string memory) {
        for (uint256 i = 0; i < totalEntries; i++) {
            if (
                keccak256(abi.encodePacked(approversById[i].approverName)) ==
                keccak256(abi.encodePacked(_approverName))
            ) {
                for (
                    uint256 j = 0;
                    j < approversById[i].vendorApprovalList.length;
                    j++
                ) {
                    if (approversById[i].vendorApprovalList[j] == _vendorId) {
                        delete approversById[i].vendorApprovalList[j];
                        approversById[i].updated = block.timestamp;
                        return (true, "Vendor removed");
                    }
                }
                return (false, "Vendor not found");
            }
        }
        return (false, "Approver not found");
    }

    function updateApprovalLevel(
        string memory _approverName,
        uint256 _newApprovalLevel
    ) public returns (bool, string memory) {
        for (uint256 i = 0; i < totalEntries; i++) {
            if (
                keccak256(abi.encodePacked(approversById[i].approverName)) ==
                keccak256(abi.encodePacked(_approverName))
            ) {
                if (approversById[i].approvalLevel == _newApprovalLevel) {
                    return (false, "Approval level is the same");
                }
                approversById[i].approvalLevel = _newApprovalLevel;
                approversById[i].updated = block.timestamp;
                return (true, "Approval level updated");
            }
        }
        return (false, "Approver not found");
    }

    //create a function to check if an approver exists
    function checkApproverExists(
        string memory _approverName
    ) public view returns (bool) {
        for (uint256 i = 0; i < totalEntries; i++) {
            if (
                keccak256(abi.encodePacked(approversById[i].approverName)) ==
                keccak256(abi.encodePacked(_approverName))
            ) {
                return true;
            }
        }
        return false;
    }

    function getApproverIdByName(
        string memory _approverName
    ) public view returns (uint256) {
        for (uint256 i = 0; i < totalEntries; i++) {
            if (
                keccak256(abi.encodePacked(approversById[i].approverName)) ==
                keccak256(abi.encodePacked(_approverName))
            ) {
                return approversById[i].id;
            }
        }
        return 0;
    }
}