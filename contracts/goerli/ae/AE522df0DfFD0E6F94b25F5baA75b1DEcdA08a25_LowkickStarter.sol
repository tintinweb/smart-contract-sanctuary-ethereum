// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract LowkickStarter {
    uint private currentCampaign;
    address owner;
    uint constant MAX_DURATION = 30 days;
    
    struct LowkickCampgaign {
        Campaign targetContract;
        bool claimed;
    }

    event CampaignStarted(
        uint curretCampaign,
        uint endTimestamp,
        uint goal,
        address organizer
    );

    mapping(uint => LowkickCampgaign) public campaigns;
    


    function start(uint _goal, uint _endsAt) external {
        require(_goal > 0);
        require(
                _endsAt <= block.timestamp + MAX_DURATION &&
                _endsAt > block.timestamp
            );

            currentCampaign += 1;

            Campaign newCampaign = new Campaign(_goal, _endsAt, msg.sender, currentCampaign);
            
            campaigns[currentCampaign] = LowkickCampgaign({
                targetContract: newCampaign,
                claimed: false
            });

            emit CampaignStarted(
                currentCampaign,
                _endsAt, 
                _goal, 
                msg.sender
            );
    }


    function onClaimed(uint _id) external {
        LowkickCampgaign storage targetCampaign = campaigns[_id];

        require(msg.sender == address(campaigns[_id].targetContract));
    
        targetCampaign.claimed = true;
    }
}

contract Campaign {
    string public name;
    uint public endsAt;
    uint public goal;
    uint public index;
    uint public pledged;
    address public organizer;
    LowkickStarter parent;
    bool claimed;

    mapping(address => uint) public pledges;

    event Pledged(uint amount, address pledger);


    constructor(uint _endsAt, uint _goal, address _organizer, uint _index) {
        endsAt = _endsAt;
        goal= _goal;
        organizer = _organizer;
        parent = LowkickStarter(msg.sender);
        index = _index;
    }


    function pledge() external payable {
        require(block.timestamp <= endsAt);
        require(msg.value > 0);
        pledged += msg.value;
        pledges[msg.sender] += msg.value;

        emit Pledged(msg.value, msg.sender);
    }


    function refundPledge(uint _amount) external {
            require(block.timestamp <= endsAt);
            require(_amount >= pledges[msg.sender]);

            pledges[msg.sender] -= _amount;
            pledged -= _amount;
            ( bool sent, bytes memory data ) = payable(msg.sender).call{ value: _amount }("");
            require(sent, "Failure! Ether not sent");
    }


    function claim() external {
        require(block.timestamp > endsAt);
        require(msg.sender == organizer);
        require(pledged >= goal);
        require(!claimed);

        claimed = true;

        payable(organizer).transfer(pledged);
    }


    function fullRefund() external {
        require(block.timestamp > endsAt);
        require(pledged < goal);


        uint refundAmount = pledges[msg.sender];
        pledges[msg.sender] = 0;

        payable(msg.sender).transfer(refundAmount);
    }
}