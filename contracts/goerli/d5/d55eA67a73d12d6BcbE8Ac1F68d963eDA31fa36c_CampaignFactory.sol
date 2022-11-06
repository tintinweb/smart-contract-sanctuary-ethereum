/**
 *Submitted for verification at Etherscan.io on 2022-11-05
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

interface RecordInterface {
    function addTransaction(
        address _from,
        address _to,
        uint _amount
    ) external;

    function getTransactions() external;

    function getTotalMoney() external;

    function addContributer(address _contributer) external;
}

contract CampaignFactory {
    struct CreateNewCampaign {
        address addressOfNewCampaign;
        string name;
        uint minimumContribution;
    }

    CreateNewCampaign[] public deployedCampaigns;

    function createCampaign(uint minimum, string memory _name) public {
        Campaign newCampaign = new Campaign(minimum, msg.sender);
        deployedCampaigns.push(
            CreateNewCampaign(address(newCampaign), _name, minimum)
        );
    }

    function getDeployedCampaigns()
        public
        view
        returns (CreateNewCampaign[] memory)
    {
        return deployedCampaigns;
    }
}

contract Campaign {
    struct Request {
        string description;
        uint value;
        address recipient;
        bool complete;
        uint approvalCount;
    }

    RecordInterface recordInstance =
        RecordInterface(0xB99389834E87902da1b577B8d2b080a1561F499F);

    mapping(address => mapping(uint => bool)) approvals;

    Request[] public requests;
    address public manager;
    uint public minimumContribution;
    mapping(address => bool) public approvers;
    uint public approversCount;

    modifier restricted() {
        require(msg.sender == manager);
        _;
    }

    constructor(uint minimum, address creator) {
        manager = creator;
        minimumContribution = minimum;
    }

    function contribute() public payable {
        require(msg.value > minimumContribution);

        if (approvers[msg.sender] == false) {
            approvers[msg.sender] = true;
            approversCount++;
        }

        recordInstance.addTransaction(msg.sender, address(this), msg.value);
        recordInstance.addContributer(msg.sender);
    }

    function createRequest(
        string memory description,
        uint value,
        address recipient
    ) public restricted {
        Request memory newRequest = Request({
            description: description,
            value: value,
            recipient: recipient,
            complete: false,
            approvalCount: 0
        });

        requests.push(newRequest);
    }

    function approveRequest(uint index) public {
        Request storage request = requests[index];

        require(approvers[msg.sender]);
        require(approvals[msg.sender][index] == false);

        approvals[msg.sender][index] = true;
        request.approvalCount++;
    }

    function finalizeRequest(uint index) public restricted {
        Request storage request = requests[index];

        require(request.approvalCount > (approversCount / 2));
        require(!request.complete);

        payable(request.recipient).transfer(request.value);

        recordInstance.addTransaction(
            address(this),
            request.recipient,
            request.value
        );

        request.complete = true;
    }

    function getSummary()
        public
        view
        returns (
            uint,
            uint,
            uint,
            uint,
            address
        )
    {
        return (
            minimumContribution,
            address(this).balance,
            requests.length,
            approversCount,
            manager
        );
    }

    function getRequestsCount() public view returns (uint) {
        return requests.length;
    }

    function getRequests() public view returns (Request[] memory) {
        return requests;
    }
}