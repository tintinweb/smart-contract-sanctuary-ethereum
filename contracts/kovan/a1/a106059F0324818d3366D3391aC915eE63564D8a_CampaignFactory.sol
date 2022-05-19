// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

import "./Campaign.sol";

contract CampaignFactory {
    address[] public deployedCampaigns;

    function createCampaign(uint minContribution) public {
        address campaign = address(new Campaign(minContribution, msg.sender));
        deployedCampaigns.push(campaign);
    }

    function getDeployedCampaigns() public view returns (address[] memory) {
        return deployedCampaigns;
    }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

contract Campaign {
    struct Request {
        string description;
        address recipient;
        uint value;
        uint approvalsCount;
        bool isCompleted;
        mapping(address => bool) approvals;
    }

    uint private requestCount;
    mapping(uint => Request) public requests;
    mapping(address => bool) public approvers;
    uint public approversCount;
    uint public minContribution;
    address public manager;

    constructor(uint _minContribution, address _manager) {
        manager = _manager;
        minContribution = _minContribution;
    }

    modifier onlyOwner() {
        require(msg.sender == manager);
        _;
    }

    function contribute() public payable {
        require(msg.value > minContribution);

        approvers[msg.sender] = true;
        approversCount += 1;
    }

    function createRequest(
        string memory _description, 
        uint _value, 
        address _recipient
    ) 
        public 
        onlyOwner 
    {
        Request storage request = requests[requestCount++];
        request.description = _description;
        request.value = _value;
        request.recipient = _recipient;
    }

    function approve(uint idx) public {
        Request storage request = requests[idx];

        require(approvers[msg.sender]);
        require(!request.approvals[msg.sender]);
        
        request.approvalsCount += 1;
        request.approvals[msg.sender] = true;
    }

    function finalizeRequest(uint idx) public onlyOwner {
        Request storage request = requests[idx];

        require(request.approvalsCount > (approversCount / 2));
        require(!request.isCompleted);

        payable(request.recipient).transfer(request.value);
        request.isCompleted = true;
    }

    function getManager() public view returns (address) {
        return manager;
    }

    function getSummary() public view returns (
        uint, uint, uint, uint, address
    ) 
    {
        return (
            minContribution,
            address(this).balance,
            requestCount,
            approversCount,
            manager
        );
    }

    function getRequestCount() public view returns (uint) {
        return requestCount;
    }

}