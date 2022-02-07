/**
 *Submitted for verification at Etherscan.io on 2022-02-06
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.22 <0.9.0;

contract CampaignManager {
    address[] public deployedContracts;

    function createCampaign(uint minContribution) public {
        Campaign newCampaign = new Campaign(minContribution, msg.sender);

        deployedContracts.push(address(newCampaign));
    }

    function getDeployedCampaigns() public view returns(address[] memory) {
        return deployedContracts;
    }
}

contract Campaign {
    struct Request {
        string description;
        uint value;
        address vendor;
        bool completed;
        uint approvedCount;
        mapping(address => bool) approvers;
    }
    address public manager;
    uint public minContribution;
    uint public donorsCount = 0;
    mapping(address => bool) public donors;
    uint private currentIndex = 0;
    mapping(uint => Request) public requests;
    uint public requestCount = 0;

    constructor(uint minAmount, address creator){
        manager = creator;
        minContribution = minAmount;
    }

    function contribute() public payable {
        require(msg.value >= minContribution, "Value should more than");
        donors[msg.sender] = true;
        donorsCount++;
    }

    function createRequest(string memory des, uint val, address vendor) public restrict {
        Request storage newRequestInStorage = requests[currentIndex];
        newRequestInStorage.description = des;
        newRequestInStorage.value = val;
        newRequestInStorage.vendor = vendor;
        newRequestInStorage.completed = false;
        newRequestInStorage.approvedCount = 0;
        currentIndex++;
        requestCount++;

    }

    function approveRequest(uint index)public {
        Request storage req = requests[index];
        require(donors[msg.sender], "You have not donated to the campaign, hence you can't approve request");
        require(!req.approvers[msg.sender], "You have voted before");

        req.approvers[msg.sender] = true;
        req.approvedCount++;
    }

    function finalizeRequest(uint index) payable public restrict {
        Request storage req = requests[index];
        require(!req.completed, "request has already been completed");
        require(req.approvedCount > (donorsCount / 2), "Request has not been approved");
        address payable vendor = payable(req.vendor);

        vendor.transfer(req.value);
        req.completed = true;
    }

    function getSummary() public view returns (
        address, uint, uint, uint, uint
    ) {
       return (
           manager,
           requestCount,
           minContribution,
           donorsCount,
            address(this).balance
       ); 
    }

    modifier restrict() {
        require(msg.sender == manager, "you are not allowed to perform this operation");
        _;
    }
}