/**
 *Submitted for verification at Etherscan.io on 2022-04-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract CampaignFactory {
    address[] public deployedCampaigns;

    function createCampaign(uint minimum) public payable {
        address newCampaignAddr = address(new Campaign(minimum, msg.sender));
        deployedCampaigns.push(newCampaignAddr);
    }

    function getDeployedCampaigns() public view returns (address[] memory) {
        return deployedCampaigns;
    }
}

contract Campaign {

    struct Request {
        string description;
        uint256 value;
        address recipient; 
        bool complete;
        uint approvalCount;
        mapping(address => bool) approvals; // we don't have to initialize these when creating a struct
    }

    address public manager;
    uint256 public minContribution;
    mapping(address => bool) public approvers;
    uint approversCount;
    Request[] public requests;

    modifier isManager() {
        require(msg.sender == manager);
        _;
    }

    constructor(uint256 minimum, address creator) {
        manager = creator;
        minContribution = minimum;
    }

    function contribute() public payable {
        require(msg.value > minContribution);
        approvers[msg.sender] = true;
        approversCount++;
    }

    function createRequest( string memory _description,
                            uint _value,
                            address _recipient
            ) public isManager {
        Request storage newRequest = requests.push();
        newRequest.description = _description;
        newRequest.value = _value;
        newRequest.recipient = _recipient;
    }

    function approveRequest(uint idx) public {
        Request storage request = requests[idx];

        require(approvers[msg.sender]); // make sure they're a donor!
        require(!request.approvals[msg.sender]); // ensure they haven't voted already
        
        request.approvals[msg.sender] = true;
        request.approvalCount++;
    }

    function finalizeRequest(uint idx) public isManager {
        Request storage request = requests[idx];

        require(!request.complete); // should only be able to approve uncompleted requests
        require(request.approvalCount > (approversCount / 2)); // over half must approve
        // require(request.value <= address(this).balance); // we need enough balance to send...

        payable(request.recipient).transfer(request.value);
        request.complete = true;
    }

    function getSummary() public view returns (uint, uint, uint, uint, address) {
        return (
            minContribution,
            address(this).balance,
            requests.length,
            approversCount,
            manager
        );
    }
    
    function getRequestsCount() public view returns (uint) {
        return requests.length;
    }
}