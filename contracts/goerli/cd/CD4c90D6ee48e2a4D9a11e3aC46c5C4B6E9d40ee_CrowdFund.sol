// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./IERC20.sol";

contract CrowdFund {
    event Launch(
        uint id,
        address indexed creator,
        uint goal,
        uint32 startAt,
        uint32 endAt
    );
    event Cancel(uint id);
    event Pledge(uint indexed id, address indexed caller, uint amount);
    event Unpledge(uint indexed id, address indexed caller, uint amount);
    event Claim(uint id);
    event Refund(uint id, address indexed caller, uint amount);

    struct Campaign {
        // Creator of campaign
        address creator;
        // Amount of tokens to raise
        uint goal;
        // Total amount pledged
        uint pledged;
        // Timestamp of start of campaign
        uint32 startAt;
        // Timestamp of end of campaign
        uint32 endAt;
        // True if goal was reached and creator has claimed the tokens.
        bool claimed;
    }

    IERC20 public immutable token;
    // Total count of campaigns created.
    // It is also used to generate id for new campaigns.
    uint public count;
    // Mapping from id to Campaign
    mapping(uint => Campaign) public campaigns;
    // Mapping from campaign id => pledger => amount pledged
    mapping(uint => mapping(address => uint)) public pledgedAmount;

    constructor(address _token) {
        token = IERC20(_token);
    }

    function launch(
        uint _goal,
        uint32 _startAt,
        uint32 _endAt
    ) external {
        require(_startAt >= block.timestamp,"start at < now");
        require(_startAt <= _endAt,"_startAt > endAt");
        require(_endAt <= block.timestamp + 90 days, "end at > max duration");

        count = count + 1;
        campaigns[count] = Campaign({
        creator : msg.sender,
        goal :_goal,
        pledged : 0,
        startAt : _startAt,
        endAt : _endAt,
        claimed : false
        });

        emit Launch(count,msg.sender,_goal,_startAt,_endAt);

    }

    function cancel(uint _id) external {
        Campaign storage campaign = campaigns[_id];
        require(campaign.creator == msg.sender,"not creator");
        require(block.timestamp < campaign.startAt, "started");
        delete campaigns[_id];
        emit Cancel(_id);

    }

    function pledge(uint _id, uint _amount) external {
        Campaign storage campaign = campaigns[_id];

        require(block.timestamp >= campaign.startAt,"not start");
        require(block.timestamp <= campaign.endAt,"ended");

        campaign.pledged += _amount;
        pledgedAmount[_id][msg.sender] += _amount;
        token.transferFrom(msg.sender, address(this), _amount);

        emit Pledge(_id,msg.sender,_amount);

    }

    function unpledge(uint _id, uint _amount) external {
        Campaign storage campaign = campaigns[_id];

        require(block.timestamp <= campaign.endAt,"ended");

        campaign.pledged -= _amount;
        token.transfer(msg.sender,_amount);

        pledgedAmount[_id][msg.sender] -= _amount;

        emit Unpledge(_id, msg.sender, _amount);


    }

    function claim(uint _id) external {
        Campaign storage campaign = campaigns[_id];

        require(msg.sender == campaign.creator,"not creator");
        require(block.timestamp > campaign.endAt, "not ended");
        require(campaign.pledged >= campaign.goal, "pledged < goal");

        require(!campaign.claimed, "claimed");

        campaign.claimed = true;

        token.transfer(campaign.creator, campaign.pledged);
        emit Claim(_id);

    }

    function refund(uint _id) external {
        Campaign storage campaign = campaigns[_id];

        require(block.timestamp > campaign.endAt, "not ended");
        require(campaign.pledged < campaign.goal, "pledged >= goal");

        uint bal = pledgedAmount[_id][msg.sender];
        pledgedAmount[_id][msg.sender] = 0;
        token.transfer(msg.sender, bal);


        emit Refund(_id, msg.sender, bal);


    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender)
    external
    view
    returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint amount);
    event Approval(address indexed owner, address indexed spender, uint amount);
}