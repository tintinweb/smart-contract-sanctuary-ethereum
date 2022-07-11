/**
 *Submitted for verification at Etherscan.io on 2022-07-11
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract CrowdFund {

    // Store all campaigns
    Campaign[] private campaigns;

    // New campaign has launched
    event CampaignLaunched(
        address contractAddress,
        address campaignCreator,
        string campaignTitle,
        string campaignDesc,
        uint deadline,
        uint goalAmount
    );

    // Function to create new campaign
    // duration parameter in number of days
    function createCampaign(
        string calldata title,
        string calldata description,
        uint duration,
        uint amount
    ) external {
        uint deadline = block.timestamp + (duration * 1 days);
        Campaign newCampaign = new Campaign(
            payable(msg.sender),
            amount,
            deadline,
            title,
            description
        );
        campaigns.push(newCampaign);
        emit CampaignLaunched(
            address(newCampaign),
            msg.sender,
            title,
            description,
            deadline,
            amount
        );
    }

    // Return all the projects
    function getCampaigns() external view returns(Campaign[] memory){
        return campaigns;
    }
}

contract Campaign {
    // Determine state of campaign
    enum State {
        Fundraising,
        Failed,
        Successful
    }

    // State Variables
    address payable public creator;
    uint public goalAmount;
    uint public completedAt;
    uint public pledgedTotal;
    uint public endAt;
    string public title;
    string public description;
    State public state = State.Fundraising;
    mapping(address => uint) public pledgeAmount;

    // Determines the state
    modifier inState(State _state) {
        require(state == _state);
        _;
    }

    // Event whenever funding is pledged
    event Pledge(
        address contributor,
        uint amount,
        uint currentTotal
    );

    event PledgeReceived(
        address contributor,
        uint pledgeAmount,
        uint pledgedTotal
    );

    event creatorFunded(address recipient);

    constructor(
        address payable  _creator,
        uint _goalAmount,
        uint _endAt,
        string memory _title,
        string memory _description
    ) {
        creator = _creator;
        goalAmount = _goalAmount;
        endAt = _endAt;
        title = _title;
        description = _description;
        pledgedTotal = 0;
    }

    function contribute() external payable inState(State.Fundraising) {
        require(msg.sender != creator, "Campaign creator cannot self fund.");
        // Save how much pledged by specific address
        pledgeAmount[msg.sender] = pledgeAmount[msg.sender] + msg.value; 
        pledgedTotal = pledgedTotal + msg.value;
        emit PledgeReceived(msg.sender, msg.value, pledgedTotal);
        isFundingFailedOrSuccessful();
    }

    function isFundingFailedOrSuccessful() public {
        if (pledgedTotal >= goalAmount) {
            state = State.Successful;
            payOut();
        } else if (block.timestamp > endAt) {
            state = State.Failed;
        }
        completedAt = block.timestamp;
    }

    function payOut() internal inState(State.Successful) returns (bool) {
        uint totalRaised = pledgedTotal;
        pledgedTotal = 0;
        if(creator.send(pledgedTotal)) {
            emit creatorFunded(creator);
            return true;
        } else {
            pledgedTotal = totalRaised;
            state = State.Successful;
        }
        return false;
    }

    function refund() public inState(State.Failed) returns (bool) {
        require(pledgeAmount[msg.sender] > 0, "Address has not made any contributions.");

        uint amountToRefund = pledgeAmount[msg.sender];
        pledgeAmount[msg.sender] = 0;

        if (!payable(msg.sender).send(amountToRefund)) {
            pledgeAmount[msg.sender] = amountToRefund;
            return false;
        } else {
            pledgedTotal = pledgedTotal - amountToRefund;
        }

        return true;
    }

    function campaignDetails() public view returns (
        address payable campaignCreator,
        string memory campaignTitle,
        string memory campaignDescription,
        uint campaignDeadline,
        State currentState,
        uint campaignPledgedTotal,
        uint campaignGoalAmount
    ) {
        campaignCreator = creator;
        campaignTitle = title;
        campaignDescription = description;
        campaignDeadline = endAt;
        currentState = state;
        campaignPledgedTotal = pledgedTotal;
        campaignGoalAmount = goalAmount;
    }
}