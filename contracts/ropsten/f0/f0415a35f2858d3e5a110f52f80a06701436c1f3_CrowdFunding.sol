// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "./MyErc20Token.sol";

contract CrowdFunding {
    event Launch(uint id, address indexed creator, uint goal, uint32 startAt, uint32 endAt);
    event Cancle(uint id);
    event Pledge(uint indexed id, address indexed caller, uint amount);
    event UnPledge(uint indexed id, address indexed caller, uint amount);
    event Claimed(uint id);
    event Refund(uint indexed id, address indexed caller, uint amount);

    struct Campaign {
        address creator;
        uint goal;
        uint32 startAt;
        uint32 endAt;
        bool claimed;
        uint pledged;
    }

    IERC20 public immutable token;
    uint public campaignCount;
    mapping(uint => Campaign) public campaigns;
    mapping(uint => mapping(address => uint)) public pledgedAmount;

    constructor(address _token) {
        token = IERC20(_token);
    }

    function launch(uint _goal, uint32 _startAt, uint32 _endAt) external {
        require(_startAt >= block.timestamp, "start time <= now");
        require(_endAt > _startAt, "end time > start time");
        require(_endAt > block.timestamp + 90 days, "end time < now");
        
        campaignCount += 1;
        campaigns[campaignCount] = Campaign({
            creator: msg.sender,
            goal: _goal,
            startAt: _startAt,
            endAt: _endAt,
            pledged: 0,
            claimed: false
        });

        emit Launch(campaignCount, msg.sender, _goal, _startAt, _endAt);
    }

    function cancle(uint _id) external {
        Campaign memory campaign = campaigns[_id];
        require(msg.sender == campaign.creator, "not creator");
        require(block.timestamp < campaign.startAt, "started");
        delete campaigns[_id];
        emit Cancle(_id);
    }

    function pledge(uint _id, uint _amount) external {
        Campaign storage campaign = campaigns[_id];
        require(block.timestamp >= campaign.startAt, "campaign not started");
        require(block.timestamp <= campaign.endAt, "campaign ended");

        campaign.pledged += _amount;
        pledgedAmount[_id][msg.sender] += _amount;
        token.transferFrom(msg.sender, address(this), _amount);

        emit Pledge(_id, msg.sender, _amount);
    }

    function unpledge(uint _id, uint _amount) external {
        Campaign storage campaign = campaigns[_id];
        require(block.timestamp <= campaign.endAt, "campaign ended");

        campaign.pledged -= _amount;
        pledgedAmount[_id][msg.sender] -= _amount;
        token.transfer(msg.sender, _amount);

        emit UnPledge(_id, msg.sender, _amount);
    }

    function claim(uint _id) external {
        Campaign storage campaign = campaigns[_id];
        require(!campaign.claimed, "already claimed");
        require(msg.sender == campaign.creator, "not owner");
        require(block.timestamp >= campaign.endAt, "not ended");
        require(campaign.pledged >= campaign.goal, "goal not achieved");

        campaign.claimed = true;
        token.transfer(msg.sender, campaign.pledged);
         
        emit Claimed(_id);
    }

    function refund(uint _id) external {
        Campaign storage campaign = campaigns[_id];
        require(block.timestamp > campaign.endAt, "not ended");
        require(campaign.pledged < campaign.goal, "goal achieved");

        uint userBal = pledgedAmount[_id][msg.sender];
        pledgedAmount[_id][msg.sender] = 0;
        token.transfer(msg.sender, userBal);

        emit Refund(_id, msg.sender, userBal);
    }
}