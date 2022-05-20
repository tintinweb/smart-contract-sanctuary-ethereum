/**
 *Submitted for verification at Etherscan.io on 2022-05-20
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract Factory {
    
    //array of created campaigns
    address[] public campaigns;

    constructor(){

    }

    function createCampaign (uint min, string memory name) public {
        Campaign newCampaign = new Campaign(min, msg.sender, name);
        campaigns.push(address(newCampaign));
    }

    function getDeployedCampaigns () public view returns (address[] memory) {
        return campaigns;
    }
}

contract Campaign {

    struct Request {
        string description;
        uint value;
        address payable vendor;
        bool complete;
        uint yesVotes;
        mapping (address => bool) votes;
    }

    uint public minContribution;
    address public manager;
    string public campaignName;
    mapping(address => bool) public approvers;
    mapping(address => bool) public contributors;
    mapping(uint => Request) public requests;
    uint public numRequests = 0;
    uint public numApprovers = 0;

    modifier onlyManager(){
        require(msg.sender == manager, "Only the manager can call this function.");
        _;
    }

    constructor (uint minContri, address creator, string memory name) {
        campaignName = name;
        minContribution = minContri;
        manager = creator;
    }


    function contribute () public payable {
        require (msg.value > 0, "Please enter a valid amount.");

        contributors[msg.sender] = true;

        if (msg.value >= minContribution) {
            approvers[msg.sender] = true;
            numApprovers++;
        }
    }


    function createRequest (string calldata desc, uint val, address payable recipient) public onlyManager {

        Request storage newRequest = requests[numRequests];
        newRequest.description = desc;
        newRequest.value = val;
        newRequest.vendor = recipient;
        newRequest.complete = false;
        newRequest.yesVotes = 0;
        numRequests++;
    }

    function approveRequest (uint index) public {

        require(approvers[msg.sender], "User is not approved.");
        Request storage currRequest = requests[index];

        require(!currRequest.votes[msg.sender], "User has already voted");
        currRequest.votes[msg.sender] = true;
        currRequest.yesVotes ++;

    }

    function finaliseRequest (uint index) external payable onlyManager{
        
        Request storage currRequest = requests[index];
        require(!currRequest.complete, "Request already completed.");
        require(currRequest.yesVotes > (numApprovers / 2), "Not enough approvals.");
        
        currRequest.vendor.transfer(currRequest.value);
        
        currRequest.complete = true;
    }
}