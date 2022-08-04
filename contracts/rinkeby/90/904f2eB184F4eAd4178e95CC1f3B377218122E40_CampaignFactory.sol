/**
 *Submitted for verification at Etherscan.io on 2022-08-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract CampaignFactory {
    address[] public deployedCampaigns;

    function createCampaign(uint minimumContribution) public {
        Campaign  newCampaign = new Campaign(minimumContribution, msg.sender);
        deployedCampaigns.push(address(newCampaign));
    }

    function getDeployedCampaigns() public view returns ( address[] memory) {
        return deployedCampaigns;
    }
}

contract Campaign {
    struct Request {
        string description;
        uint value;
        address payable recipient;
        bool complete;
        uint approvalCount;
        mapping(address => bool) approvals;
        bool isModify;
    }

    uint public numRequests;   // number of requests
    mapping(uint => Request) public requests;  // 這邊沒有宣告成public導致compile時abi沒有此function 
    address public manager;
    uint public minimumContribution;
    mapping(address => bool) public approvers;
    uint public numApprovers; //number of approvers

    modifier onlyManager() {
        require(msg.sender == manager);
        _;
    }

    constructor (uint minimum, address creator)  {
        manager = creator;
        minimumContribution = minimum;
    }

    function contribute() public payable {
        require(msg.value > minimumContribution);
        approvers[msg.sender] = true;
        numApprovers++;
    }

    function createRequest (string memory description, uint value, address payable recipient)  public onlyManager {

          Request storage newRequest = requests[numRequests++];
            newRequest.description = description;
            newRequest.value = value;
            newRequest.recipient = recipient;
            newRequest.complete = false;
            newRequest.approvalCount = 0;
            newRequest.isModify= false;

    }

    function approveRequest(uint index) public {
        Request storage request = requests[index];

        require(approvers[msg.sender]);
        require(!request.approvals[msg.sender]);

        request.approvals[msg.sender] = true;
        request.approvalCount++;
    }

    function modifyRequest(uint index, string memory description, uint value, address payable recipient ) public onlyManager {
        Request storage request = requests[index];
        require(!request.complete);
        request.description= description;
        request.recipient = recipient;
        request.value = value;
        request.isModify = true;
    }

    function finalizeRequest(uint index) public onlyManager {
        Request storage request = requests[index];

        //If request has been changed, it needs a half of approvers approval to finalize
        if(request.isModify){
            require(request.approvalCount > (numApprovers / 2));
        }

        require(!request.complete);
        request.recipient.transfer(request.value);
        request.complete = true;
    }

    function getSummary() public view returns (
        uint, uint, uint, uint, address
    ){
        return(
        minimumContribution,
        address(this).balance,
        numRequests,
        numApprovers,
        manager
        );
    }

    function getRequests(uint index) public view returns (
        string memory, uint, address payable, bool, uint, bool
    ){
        Request storage request = requests[index];
        return(
        request.description,
        request.value,
        request.recipient,
        request.isModify,
        request.approvalCount,
        request.complete
        );
    }


}