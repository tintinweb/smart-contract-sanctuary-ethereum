/**
 *Submitted for verification at Etherscan.io on 2022-11-03
*/

// File: contracts/Crowdfund.sol




pragma solidity ^0.8.0;

contract Crowdfund {
    event StartCampaign(uint id, address creator, string title, string description,string img_url, 
        uint goal,uint tier1Amount, uint minContribution, uint startTime, uint endTime);
    event DropCampaign(uint id);

    event Donate(uint indexed _id, address indexed caller,uint amount);
    event Withdraw(uint indexed _id,address indexed caller,uint amount);

    event PayoutOnGoalMet(uint id);
    event Reimburse(uint id, address indexed caller, uint amount);


    struct Campaign {
        address payable creator;
        string title;
        string description;
        string img_url;
        uint currentAmount;
        uint goal;
        uint minContribution; //in weis
        uint tier1Amount;
        uint32 startTime;
        uint32 endTime;
        bool claimed;
    }
    uint public campaignCount;
    mapping(uint=> Campaign) public ongoingCampaigns; // map count to campaign e.g 0 => Campaign object
    mapping(uint=> mapping(address=>uint)) public potentialDonations; // map count to dict e.g 0 => {address1:100wei, ...., addressN:200wei}
    mapping(uint=> mapping(address=>bool)) public rewarded; // Map count/index of campaign to dict e.g. {addres1: True,..., addressN: False}

    // Allows entrepreuners to start a campaign
    function startCampaign(string memory _title, string memory _description, string memory _img_url,uint _goal, uint _minContribution,
                                            uint _tier1Amount, uint32 _startTime, uint32 _endTime) external {
        require(_startTime >= block.timestamp, "start must be after block creation");
        require(_startTime <= _endTime, "start must be before endTime");
        campaignCount++;
        ongoingCampaigns[campaignCount] = Campaign({
            creator : payable(msg.sender),
            title: _title,
            description: _description,
            img_url: _img_url,    
            currentAmount: 0,
            goal: _goal,
            minContribution: _minContribution,
            tier1Amount: _tier1Amount,
            startTime: _startTime,
            endTime: _endTime,       
            claimed: false
        });
        emit StartCampaign(campaignCount, msg.sender, _title, _description,_img_url,
            _goal,_tier1Amount,_minContribution, _startTime, _endTime);

    }

    modifier isOwner(uint _id) {
        require(msg.sender == ongoingCampaigns[_id].creator, "Only creator of this campaign can call this function.");
        _;
    }

    // Allows creator to drop a campaign that has not yet started
    function dropCampaign(uint _id) public isOwner(_id) {
        Campaign memory campaign = ongoingCampaigns[_id];
        require(block.timestamp < campaign.startTime, "Campaign has already started");
        delete ongoingCampaigns[_id];
        emit DropCampaign(_id);
    
    }
    
    // Allows people to donate and support a campaign
    function donate(uint _id) public payable {
        Campaign storage campaign = ongoingCampaigns[_id];
        require(block.timestamp >= campaign.startTime, "Campaign has yet to be started");
        require(_id<= campaignCount, "No such Campaign!");
        require(block.timestamp <= campaign.endTime, "Campaign has ended and is not receiving any more donation");
        require(msg.value >= campaign.minContribution, "Amount supported must be more than minimum contribution");
        campaign.currentAmount += msg.value;
        potentialDonations[_id][msg.sender] += msg.value;
        emit Donate(_id, msg.sender, msg.value);
    }


    // Allows donor to withdraw donation if it is still within the timeframe of the campaign
    function withdraw(uint _id, uint _amount) public payable {
        Campaign storage campaign = ongoingCampaigns[_id];
        require(block.timestamp <= campaign.endTime, "Campaign has ended and withdraw operation can't be carried out");
        require(potentialDonations[_id][msg.sender] >= _amount, "The amount you are trying to withdraw is < the amount you have pledged");
        campaign.currentAmount -= _amount;
        potentialDonations[_id][msg.sender] -= _amount;
        address payable withdrawee = payable(msg.sender);
        withdrawee.transfer(_amount);

        emit Withdraw(_id, msg.sender, _amount);
    }      

    // Allows creator to access funds when goal's met
    function payoutOnGoalMet(uint _id)  public payable isOwner(_id) {
        Campaign storage campaign = ongoingCampaigns[_id];
        require(block.timestamp > campaign.endTime, "Campaign has not ended");
        require(campaign.currentAmount >= campaign.goal, "Campaign did not meet its goal and funds can't be accessed");
        require(!campaign.claimed, "Payout has already been claimed");
        uint payout = campaign.currentAmount;

        campaign.currentAmount = 0;
        campaign.claimed = true;
        address payable owner = payable(msg.sender);
        owner.transfer(payout);
        emit PayoutOnGoalMet(_id);
    }

    // Donors get incentive (e.g. merch) if their total donation is above a certain level after the campaign has ended
    function getTierReward(uint _id) external {
        Campaign storage campaign = ongoingCampaigns[_id];
        require(block.timestamp > campaign.endTime, "Campaign has not ended");
        require(campaign.currentAmount >= campaign.goal, "Campaign did not meet its goal and tier Reward can't be accessed");
        if ( campaign.tier1Amount<potentialDonations[_id][msg.sender]){
            rewarded[_id][msg.sender] = true;
        }
    
    }

    // Sends money back only after campaign has finished and campaign did not meet its goals
    function reimburse(uint _id) external {
        Campaign storage campaign = ongoingCampaigns[_id];
        require(block.timestamp > campaign.endTime, "Campaign has not ended");
        require(campaign.currentAmount < campaign.goal, "Campaign has met its goal and operation reimburse cannot be carried out");
        uint bal = potentialDonations[_id][msg.sender];       
        require(bal>=0, "You have been reimbursed already.");
        campaign.currentAmount -= bal;

        potentialDonations[_id][msg.sender] = 0;
        address payable reimbursee = payable(msg.sender);
        reimbursee.transfer(bal);
        emit Reimburse(_id, msg.sender, bal);
    }
    // Allows donor to view all campaigns he has donated to
    function retrieveAllBackedCampaigns() public view returns(uint[] memory) {
        uint num = 0;
        uint[] memory backedCampaign = new uint[](campaignCount);
        for (uint i = 1; i<=campaignCount; i++){
            if (potentialDonations[i][msg.sender] == 0) {
                continue;
            }
            backedCampaign[num++] = i;
        }
        return backedCampaign;
    }


    function getAllCampaigns() public view returns (Campaign[] memory){
        Campaign[] memory allCampaigns = new Campaign[](campaignCount);
        for (uint i = 0; i<campaignCount; i++){
            Campaign memory specificCampaign = ongoingCampaigns[i+1];
            allCampaigns[i] =  specificCampaign;
        }
        return allCampaigns;
    }

    //Allows creator to view all created campaigns
    function retrieveAllCreatedCampaigns() public view returns(uint[] memory) {
        uint num = 0;
        uint[] memory createdCampaign = new uint[](campaignCount);
        for (uint i = 1; i<=campaignCount; i++){
            Campaign memory specificCampaign = ongoingCampaigns[i];

            if(payable(msg.sender) == specificCampaign.creator) {
                createdCampaign[num++] = i;
            }
        }
        return createdCampaign;
    }
}