// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;


contract CrowdGaming {

  // Events
      event Launch(uint id, address indexed owner, string title, uint goal, string description, uint256 startAt, uint256 endAt);
      event Cancel(uint id);
      event Pledge(uint indexed id, address indexed pledger, uint amount);
      event Withdraw(uint id);
      event Refund(uint indexed id, address indexed pledger, uint amount);

  // Struct for Campaign
    struct Campaign {
      address owner;
      string title;
      string description;
      uint pledged;
      uint goal;
      uint256 startAt;
      uint256 endAt;
      bool claimed;
    }

  // State variables
    uint public totalCampaigns;
    mapping (uint => Campaign) public campaigns;
    mapping (uint => mapping(address => uint)) public pledgedAmount;


  // Function to launch a campaign - public return the campaign ID
    function launchCampaign(string calldata _title, string calldata _description, uint _goal, uint256 _startAt, uint256 _endAt) external {
    // Require campaign length to be a future date
    require(_startAt >= block.timestamp, "Invalid start date");
    require(_endAt >= _startAt, "Invalid end date");
    require(_endAt <= block.timestamp + 30 days, "Cannot go past 30 days");
    require(_goal > 0, "Goal must be greater than 0");
    // Add to totalCampaign variable
    totalCampaigns++;
    // Set new variables for campaign
    campaigns[totalCampaigns] = Campaign({
      owner: msg.sender,
      title: _title,
      goal: _goal,
      pledged: 0,
      description: _description,
      startAt: _startAt,
      endAt: _endAt,
      claimed: false
    });
    // Emit Launch
    emit Launch(totalCampaigns, msg.sender, _title, _goal, _description, _startAt, _endAt);
    
    }
  // Function to cancel a campaign
    function cancelCampaign(uint _id) external {
      Campaign memory campaign = campaigns[_id];
      require(msg.sender == campaign.owner, "Not owner");
      require(block.timestamp < campaign.startAt, "Has started");
      // Delete campaign
      delete campaigns[_id];
      // Emit Cancel
      emit Cancel(_id);
    }


  // Function to pledge to a campaign 
    function pledgeTo(uint _id) external payable {
    Campaign storage campaign = campaigns[_id];
    require(block.timestamp >= campaign.startAt, "Hasn't started");
    require(block.timestamp <= campaign.endAt, "Has ended");
    // Prevent reentry
    campaign.pledged += msg.value;
    pledgedAmount[_id][msg.sender] += msg.value;
    // Emit Pledge
    emit Pledge(_id, msg.sender, msg.value);
    }


  // Function to widthraw funds from a campaign 
    function withdrawFrom(uint _id) external payable {
      Campaign storage campaign = campaigns[_id];
      require(msg.sender == campaign.owner, "Not owner");
      require(block.timestamp > campaign.endAt, "Hasn't ended");
      require(campaign.pledged >= campaign.goal, "Didn't meet goal");
      require(!campaign.claimed, "Already claimed");
      campaign.claimed = true;
      // Prevent reentry
      uint amount = campaign.pledged;
      campaign.pledged = 0;
      // Send funds to owner and check for success
      (bool success, ) = campaign.owner.call{value: amount}("");
      require(success, "Failed to send Ether");
      // Emit Withdraw
      emit Withdraw(_id);
    }


  // Function to refund funds if the campaign isn't met 
    function refund(uint _id) external payable {
      address donor = msg.sender;
      Campaign storage campaign = campaigns[_id];
      require(block.timestamp > campaign.endAt, "Hasn't ended");
      require(campaign.pledged < campaign.goal, "Total less than goal");
      require(campaign.owner != address(0), "Campaign does not exist");
      // Prevet reentry
      uint balance = pledgedAmount[_id][msg.sender];
      pledgedAmount[_id][msg.sender] = 0;
      // Send ether back to donor and check for success
      (bool success, ) = donor.call{value: balance}("");
      require(success, "Failed to send ether");
      // Emit Refund
      emit Refund(_id, msg.sender, balance);
    }

 }