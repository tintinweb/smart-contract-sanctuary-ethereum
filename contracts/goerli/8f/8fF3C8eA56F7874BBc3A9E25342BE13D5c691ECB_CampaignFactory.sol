// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract CampaignFactory {
    address payable[] public deployedCampaigns;

    function createCampaign(uint256 minimum) public {
        address newCampaign = address(new Campaign(minimum, msg.sender));
        deployedCampaigns.push(payable(newCampaign));
    }

    function getDeployedCampaigns()
        public
        view
        returns (address payable[] memory)
    {
        return deployedCampaigns;
    }
}

contract Campaign {
    struct Request {
        //describes why the request is being created
        string description;
        //amount of money that the manager wants to send to the vendor
        uint256 value;
        //address that the money will be sent to
        address recipient;
        //true if the request has already been processes
        bool complete;
        uint256 approvalCount;
        mapping(address => bool) approvals;
    }

    Request[] public requests;
    address public manager;
    uint256 public minimumContribution;
    mapping(address => bool) public approvers;
    uint256 public approversCount;

    modifier restricted() {
        require(msg.sender == manager);
        _;
    }

    constructor(uint256 minimum, address creator) {
        manager = creator;
        minimumContribution = minimum;
    }

    //called when someone wants to donate money to the campaign
    //and become an 'approver'
    function contribute() public payable {
        require(msg.value > minimumContribution);

        approvers[msg.sender] = true;
        approversCount++;
    }

    //called by the manager to create a new 'spending request'
    function createRequest(
        string memory description,
        uint256 value,
        address recipient
    ) public restricted {
        Request storage newRequest = requests.push();
        newRequest.description = description;
        newRequest.value = value;
        newRequest.recipient = recipient;
        newRequest.complete = false;
        newRequest.approvalCount = 0;
    }

    //called by each contributor to approve a spending request
    function approveRequest(uint256 index) public {
        //manipulate the Request struct in storage
        Request storage request = requests[index];
        //require that inside the approvers mapping we should receive a true result
        //the person approving the request has in fact contributed
        require(approvers[msg.sender]);
        //require that the person approving hasn't approved before, no double counts
        require(!request.approvals[msg.sender]);

        request.approvals[msg.sender] = true;
        //how many people have joined contract
        request.approvalCount++;
    }

    //after a request has gotten enough approvals, the manager can call this to get money sent to the vendor
    function finalizeRequest(uint256 index) public restricted {
        Request storage request = requests[index];

        //greater than 50% of people must approve before funds released
        require(request.approvalCount > (approversCount / 2));
        require(!request.complete);
        //recipient receives funds
        payable(request.recipient).transfer(request.value);
        //when funds are paid, flag is flipped
        request.complete = true;
    }

    function getSummary()
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
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

    function getRequestsCount() public view returns (uint256) {
        return requests.length;
    }
}

//   Deploying 'CampaignFactory'
//    ---------------------------
//    > transaction hash:    0x903598cc6331b9ecf81a7b23a45acaf772366df11617a5a50bffebc16269cd5b
//    > Blocks: 0            Seconds: 8
//    > contract address:    0x8fF3C8eA56F7874BBc3A9E25342BE13D5c691ECB
//    > block number:        8559483
//    > block timestamp:     1677406908
//    > account:             0x8f5681528c217F21e51E3Ee90a89e7D04E07D33d
//    > balance:             0.562471935146184835
//    > gas used:            1301807 (0x13dd2f)
//    > gas price:           2.500099938 gwei
//    > value sent:          0 ETH
//    > total cost:          0.003254647599987966 ETH

//   Deploying 'Campaign'
//    --------------------
//    > transaction hash:    0xc95caa063461f8900fed9a8db52f9b6be659e6eb10fb1995fc458b39352300ab
//    > Blocks: 1            Seconds: 8
//    > contract address:    0xea7F508Ab4e3B73b75978906843636a1E1484f3c
//    > block number:        8559486
//    > block timestamp:     1677406944
//    > account:             0x8f5681528c217F21e51E3Ee90a89e7D04E07D33d
//    > balance:             0.559901229862825839
//    > gas used:            1028233 (0xfb089)
//    > gas price:           2.500119412 gwei
//    > value sent:          0 ETH
//    > total cost:          0.002570705283358996 ETH