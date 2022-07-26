// SPDX-License-Identifier: MIT
pragma solidity ^0.4.26;

// contract CampaignFactory{
//     address[] public deployedContracts;
//     function createCampaign(uint minimum) public {
//         address newCampaign = new campaign(minimum, msg.sender);
//         deployedContracts.push(newCampaign);
//     }
//     function getDeployedcampaigns() public view returns (address[]){
//         return deployedContracts;
//     }
// }
contract campaign {
    struct Request {
        string description;
        uint256 value;
        address recipient;
        bool complete;
        uint256 approvalcount;
        mapping(address => bool) approvals;
    }
    Request[] public requests;
    address public Manager;
    uint256 public Minimum_contibution;
    //uint256 private minimum;
    mapping(address => bool) public Approvers;
    uint256 public approversCount;

    modifier Mandatory() {
        require(msg.sender == Manager);
        _;
    }

    constructor() public {
        Manager = msg.sender;
        //Minimum_contibution = minimum;
    }

    function Contribute() public payable {
        require(
            msg.value > Minimum_contibution,
            "The Campaign accepts Minimum Value to contribute."
        );
        Approvers[msg.sender] = true;
        approversCount++;
    }

    function createRequest(
        string memory description,
        uint256 value,
        address recipient
    ) public {
        Request memory newRequest = Request({
            description: description,
            value: value,
            recipient: recipient,
            complete: false,
            approvalcount: 0
        });
        requests.push(newRequest);
    }

    function approveRequests(uint256 index) public {
        Request storage request = requests[index];
        require(Approvers[msg.sender], "Only contributers can access!");
        require(
            !request.approvals[msg.sender],
            "Voting accessing used only once"
        );
        request.approvals[msg.sender] = true;
        request.approvalcount++;
    }

    function finalizeRequest(uint256 index) public {
        Request storage request = requests[index];
        require(
            Manager == msg.sender,
            "Only Manager can finalize the Request."
        );
        require(
            request.approvalcount > approversCount / 2,
            "Minimum number of vote required to proceed."
        );
        require(!request.complete);
        request.complete = true;
        request.recipient.transfer(request.value);
    }
}