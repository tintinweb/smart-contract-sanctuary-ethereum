/**
 *Submitted for verification at Etherscan.io on 2022-09-17
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

// Since we will not use all functions of ERC20 contract, we don't need to specify all of them in the interface
// https://docs.openzeppelin.com/contracts/4.x/erc20
interface IERC20 {
    function transfer(address, uint) external returns (bool);

    function transferFrom(
        address,
        address,
        uint
    ) external returns (bool);
}

contract CrowdFund {
    struct Campaign {
        address creator; // Creator of the campaign
        uint256 goal; // Amount of tokens to raise
        uint256 pledged; // Total amount pledged
        uint32 startAt; // Timestamp of start of campaign
        uint32 endAt; // Timestamp of end of campaign
        bool isClaimed; // True if goal was reached and creator has claimed tokens
    }

    IERC20 public immutable token;
    // Amount of created campaigns
    // We can use count variable to generate unique id for every campaign
    // If you want you can use Counter library from OpenZeppelin
    // https://docs.openzeppelin.com/contracts/4.x/api/utils#Counters
    uint256 public count; 

    mapping(uint256 => Campaign) public campaigns; // Mapping of campaign ID to campaign

    mapping(uint256 => mapping(address => uint256)) pledgedAmount; // Mapping of campaign ID => pledger => pledged amount

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

    constructor(address _tokenAddress) {
        token = IERC20(_tokenAddress);
    }

    // Creates a campaign
    function launch(uint256 _goal, uint32 _startAt, uint32 _endAt) external {
        require(_startAt >= block.timestamp, "Campaign start must be less than block.timestamp");
        require(_endAt >= _startAt, "Campaign end must be greater than campaign start");
        require(_endAt <= _startAt + 90 days, "Campaign exceeds max campaign duration");

        count+=1;
        campaigns[count] = Campaign({
            creator: msg.sender,
            goal: _goal,
            pledged: 0,
            startAt: _startAt,
            endAt: _endAt,
            isClaimed: false 
        });

        emit Launch(count, msg.sender, _goal, _startAt, _endAt);
    }

    // Creator can cancel campaign before it is started
    function cancel(uint256 _campaignId) external {
        Campaign memory campaign = campaigns[_campaignId];
        require(campaign.creator == msg.sender, "Only creator of the campaign can cancel");
        require(block.timestamp < campaign.startAt, "Campaign is started");

        delete campaigns[_campaignId];
        emit Cancel(_campaignId);

    }

    // Deposit money to a campaign
    function pledge(uint256 _campaignId, uint256 _amount) external {
        Campaign storage campaign = campaigns[_campaignId];
        require(block.timestamp >= campaign.startAt, "Campaign is not started");
        require(block.timestamp <= campaign.endAt, "Campaign is ended");

        campaign.pledged += _amount;
        pledgedAmount[_campaignId][msg.sender] += _amount;
        // In the OpenZeppelin ERC20 implementation transferFrom function returns a boolean value
        // Check if the transfer is successfull
        assert(token.transferFrom(msg.sender, address(this), _amount));
  
        emit Pledge(_campaignId, msg.sender, _amount);    
    }

    // Users can withdraw their money before the campaign is ended
    function unpledge(uint256 _campaignId, uint256 _amount) external {
        Campaign storage campaign = campaigns[_campaignId];
        require(block.timestamp <= campaign.endAt, "Campaign is ended");

        campaign.pledged -= _amount;
        pledgedAmount[_campaignId][msg.sender] -= _amount;
        // Check if the transfer is successfull
        assert(token.transfer(msg.sender, _amount));

        emit Unpledge(_campaignId, msg.sender, _amount);
    }

    function claim(uint256 _campaignId) external {
        Campaign storage campaign = campaigns[_campaignId];
        require(campaign.creator == msg.sender, "Only creator can claim tokens");
        require(block.timestamp > campaign.endAt, "Campaign is not ended");
        require(campaign.pledged >= campaign.goal, "Goal is not reached");
        require(!campaign.isClaimed, "Tokens are already claimed");

        campaign.isClaimed = true;
        // Check if the transfer is successfull
        assert(token.transfer(msg.sender, campaign.pledged));

        emit Claim(_campaignId);

    }

    // If the campaign is ended and the goal is not reached users can withdraw their money
    function refund(uint256 _campaignId) external {
        Campaign memory campaign = campaigns[_campaignId];
        require(block.timestamp > campaign.endAt, "Campaign is not ended");
        require(campaign.pledged < campaign.goal, "Goal is reached");

        uint balance =  pledgedAmount[_campaignId][msg.sender];
        pledgedAmount[_campaignId][msg.sender] = 0;
        assert(token.transfer(msg.sender, balance));

        emit Refund(_campaignId, msg.sender, balance);
    }
}