/**
 *Submitted for verification at Etherscan.io on 2022-09-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CreateTender{
    address owner;
    uint256 tenderCount;
    
    constructor() {
        owner=msg.sender;
    }
    event createTender(string tenderName,string tenderDesc,uint maxBudget);

    struct TenderStruct{
       address manager;
       string tenderName;
       string tenderDesc;
       uint maxBudget;
    }

    TenderStruct[] tenderDetails;

    function addToBlockchain( string memory tenderName,string memory tenderDesc,uint maxBudget) public {
        require(msg.sender == owner,"Only the manager can create a tender");
        tenderCount +=1;
        tenderDetails.push(TenderStruct(msg.sender,tenderName,tenderDesc,maxBudget));

        emit createTender(tenderName, tenderDesc, maxBudget);
    }

    function getTenderDetails() public view returns (TenderStruct[] memory) {
        return tenderDetails;
    }

    function getTenderCount() public view returns (uint256) {
        return tenderCount;
    }
}