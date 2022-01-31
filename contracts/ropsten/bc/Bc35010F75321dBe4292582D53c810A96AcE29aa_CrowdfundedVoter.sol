/**
 *Submitted for verification at Etherscan.io on 2022-01-30
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract CrowdfundedVoter {
    // Campaign struct keeps track of votes, voteOptions, title and other metadata
    struct Campaign {
        mapping(address => Voter) voters;
        mapping(uint => VoteOption) voteOptions;
        uint voteOptionsAmount;
        string title;
        string description;
        uint goalInGWei;
        uint currentFundingInGWei;
        string[] keywords;
        uint endDateTime;
        string picURL;
        address creator;
    }

    // CampaignConfig is used to pass as a parameter/return value to functions that need less campaign data
    struct CampaignConfig {
        uint voteOptionsAmount;
        string title;
        string description;
        uint goalInGWei;
        uint currentFundingInGWei;
        string[] keywords;
        uint endDateTime;
        string picURL;
        address creator;
    }

    // Voter struct, keeps track if a wallet voted and who they voted for
    struct Voter {
        bool voted;
        uint vote;
    }

    // VoteOption keeps track of one vote option's title and amount of votes
    struct VoteOption {
        string title;
        uint votes;
    }

    // State: uint to Campaigns mapping, as well as keeping track of the total campaigns
    // This last variable is necessary to iterate through the mapping
    mapping(uint => Campaign) public campaigns;
    uint public campaignsCount;

    // Constructor when the contract is created on the network
    constructor() {
       campaignsCount = 0;
    }

    // voteAndBack allows a caller to vote and back a specific campaign
    function voteAndBack(uint _cid, uint _voteOption) external payable returns (bool) {
        require(block.timestamp < campaigns[_cid].endDateTime, "Campaign is done already");
        require(campaigns[_cid].creator != msg.sender, "User cannot vote, they are the creator");
        require(!campaigns[_cid].voters[msg.sender].voted, "User has already voted");

        campaigns[_cid].voters[msg.sender].voted = true;
        campaigns[_cid].voters[msg.sender].vote = _voteOption;
        campaigns[_cid].voteOptions[_voteOption].votes += 1;
        campaigns[_cid].currentFundingInGWei += msg.value;

        return true;
    }

    // claim allows the campaign creator to claim the money when the campaign is done
    function claim(uint _cid) external returns (bool) {
        require(campaigns[_cid].creator == msg.sender, "You cannot claim without being the creator");
        require(campaigns[_cid].endDateTime < block.timestamp, "The campaign is not yet done");
        require(campaigns[_cid].currentFundingInGWei > 0, "No funds remaining");

        uint amount = campaigns[_cid].currentFundingInGWei;
        campaigns[_cid].currentFundingInGWei = 0;

        if (!payable(msg.sender).send(amount)) {
            campaigns[_cid].currentFundingInGWei = amount;
            return false;
        }
        
        return true;
    }

    // Get the current campaignsCount
    function getCampaignsCount() external view returns (uint){
        return campaignsCount;
    }

    // Get all campaigns
    function getAllCampaigns() external view returns (CampaignConfig[] memory _campaigns){
        _campaigns = new CampaignConfig[](campaignsCount);
        
        for (uint256 i = 0; i < campaignsCount; i++) {
            _campaigns[i] = CampaignConfig(_campaigns[i].voteOptionsAmount, _campaigns[i].title, _campaigns[i].description, _campaigns[i].goalInGWei, _campaigns[i].currentFundingInGWei, _campaigns[i].keywords, _campaigns[i].endDateTime, _campaigns[i].picURL, _campaigns[i].creator);
        }
    }

    // Get a campaign's current metadata
    function getCampaignMetadata(uint id) external view returns (VoteOption[] memory _voteOptions, uint _voteOptionsAmount, string memory _title, string memory _description, uint _goalInGWei, uint _currentFundingInGWei, string[] memory _keywords, uint _endDateTime, bool _callingUserVoted, string memory _picURL, address _creator){
        _voteOptions = new VoteOption[](campaigns[id].voteOptionsAmount);
        
        for (uint256 i = 0; i < campaigns[id].voteOptionsAmount; i++) {
            _voteOptions[i] = campaigns[id].voteOptions[i];
        }

        _voteOptionsAmount = campaigns[id].voteOptionsAmount;
        _title = campaigns[id].title;
        _description = campaigns[id].description;
        _goalInGWei = campaigns[id].goalInGWei;
        _currentFundingInGWei = campaigns[id].currentFundingInGWei;
        _keywords = campaigns[id].keywords;
        _endDateTime = campaigns[id].endDateTime;
        _callingUserVoted = campaigns[id].voters[msg.sender].voted;
        _picURL = campaigns[id].picURL;
        _creator = campaigns[id].creator;
    }

    // Create a campaign
    function createCampaign(VoteOption[] calldata _voteOptions, CampaignConfig calldata _campaign) external returns (bool){
        campaigns[campaignsCount].voters[msg.sender] = Voter(true, 0);
        campaigns[campaignsCount].voteOptionsAmount = _campaign.voteOptionsAmount;
        campaigns[campaignsCount].title = _campaign.title;
        campaigns[campaignsCount].description = _campaign.description;
        campaigns[campaignsCount].goalInGWei = _campaign.goalInGWei;
        campaigns[campaignsCount].currentFundingInGWei = _campaign.currentFundingInGWei;
        campaigns[campaignsCount].endDateTime = _campaign.endDateTime;
        campaigns[campaignsCount].picURL = _campaign.picURL;
        campaigns[campaignsCount].creator = msg.sender;

        addArrayTypesToStorage(_campaign.keywords, _voteOptions, _campaign.voteOptionsAmount);

        campaignsCount = campaignsCount + 1;

        return true;
    }

    // Helper to remove stack too deep errors
    function addArrayTypesToStorage(string[] memory _keywords, VoteOption[] memory _voteOptions, uint _voteOptionsAmount) private {
        for (uint256 i = 0; i < _keywords.length; i++) {
            campaigns[campaignsCount].keywords.push(_keywords[i]);
        }

        for (uint256 i = 0; i < _voteOptionsAmount; i++) {
            campaigns[campaignsCount].voteOptions[i].title = _voteOptions[i].title;
            campaigns[campaignsCount].voteOptions[i].votes = 0;
        }
    }
}