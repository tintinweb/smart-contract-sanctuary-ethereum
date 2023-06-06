// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract CrowdFunding {
    struct SpendRequest {
        string message;
        uint256[] votes;
    }
    struct Campaign {
        address owner;
        string title;
        string description;
        uint256 target;
        uint256 deadline;
        uint256 amountCollected;
        string image;
        address[] donators;
        uint256[] donations;
        SpendRequest spendRequest;
        string state;
    }
    mapping(uint256 => Campaign) public campaigns;

    uint256 public numberOfCompaigns = 0;

    function createCampaign(address _owner, string memory _title, string memory _description, uint256 _target, uint256 _deadline, string memory _image) public returns (uint256) {
        Campaign storage campaign = campaigns[numberOfCompaigns];

        // is everything ok?
        require(
            campaign.deadline < block.timestamp,
            "The deadline should be a date in the future"
        );

        campaign.owner = _owner;
        campaign.title = _title;
        campaign.description = _description;
        campaign.target = _target;
        campaign.deadline = _deadline;
        campaign.amountCollected = 0;
        campaign.image = _image;
        campaign.state = "Ongoing";

        numberOfCompaigns++;

        return numberOfCompaigns - 1;
    }

    function donateToCampaign(uint256 _id) public payable {
        uint256 amount = msg.value;
        Campaign storage campaign = campaigns[_id];
        campaign.donators.push(msg.sender);
        campaign.donations.push(amount);

        campaign.amountCollected = campaign.amountCollected + amount;
    }

    function vote(uint256 _campaignId, uint voteValue) public {
        Campaign storage campaign = campaigns[_campaignId];

        for (uint i = 0; i < campaign.donators.length; i++) {
            if (msg.sender == campaign.donators[i]) {
                campaign.spendRequest.votes[i] = voteValue;
            }
        }

       uint cnt = 0;
       for (uint i = 0; i < campaign.spendRequest.votes.length; i++) {
          if (campaign.spendRequest.votes[i] == 1) {
               cnt++;
          }
       }

        if (campaign.amountCollected >= campaign.target && cnt >= campaign.spendRequest.votes.length/2) {
            payable(campaign.owner).transfer(campaign.amountCollected);
            campaign.state = "Finished";
        }
    }

    function getVotes(uint256 _campaignId) public view returns (uint256[] memory) {
        uint256[] memory votes = campaigns[_campaignId].spendRequest.votes;

        return votes;
    }

    function getDonators(uint256 _id) public view returns (address[] memory, uint256[] memory) {
        return (campaigns[_id].donators, campaigns[_id].donations);
    }

    function getCampaigns() public view returns (Campaign[] memory) {
        Campaign[] memory allCampaigns = new Campaign[](numberOfCompaigns);

        for (uint i = 0; i < numberOfCompaigns; i++) {
            Campaign storage item = campaigns[i];

            allCampaigns[i] = item;
        }
        return allCampaigns;
    }

     function getSpendRequests(uint256 _id) public view returns (SpendRequest memory) {
          return (campaigns[_id].spendRequest);
     }

     function createSpendRequest(uint256 _campaignId, string memory message) public {
          Campaign storage campaign = campaigns[_campaignId];
          uint256[] memory votes = new uint256[](campaign.donators.length);
          for (uint i = 0; i < campaign.donators.length; i++) {
               votes[i] = 0;
          }
          campaign.spendRequest = SpendRequest({message: message, votes: votes});
          campaign.state = "Voting";
     }

     function refund(uint256 _campaignId) public {
          Campaign storage campaign = campaigns[_campaignId];
          // require(block.timestamp >= campaign.deadline, "The campaign is not over yet");

          // Count positive votes for the owner
          uint cnt = 0;
          for (uint i = 0; i < campaign.spendRequest.votes.length; i++) {
               if (campaign.spendRequest.votes[i] == 1) {
                    cnt++;
               }
          }

          require(cnt < campaign.spendRequest.votes.length/2, "The majority decided that the amount collected should go to the owner of the campaign");

          for (uint i = 0; i < campaign.donators.length; i++) {
               uint amount = campaign.donations[i];
               payable(campaign.donators[i]).transfer(amount);
          }

          campaign.state = "Refunded";
      }
    
    function getCampaignState(uint256 _campaignId) public view returns (string memory) {
        return campaigns[_campaignId].state;
    }

}